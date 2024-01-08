// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Citizenship.sol";
import "./CitizenToken.sol";
import "./CitizenDaoLedger.sol";
import "./Roles.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Context.sol";

contract CitizenDao is Context, AccessControlEnumerable {
    using Counters for Counters.Counter;

    uint256 public voteTimeBlocks;    
    CitizenToken public citizenToken;
    Citizenship public citizenship;
    CitizenDaoLedger public ledger;
    Counters.Counter private _voteCounter;
    
    
    struct MintingVote {
        mapping (uint256 => bool) votes;
        uint256 totalVotes;
        uint256 votesNeeded;
        uint256 votingTokenCutoffIndex;
        uint256 blockCutoff;
        uint256 amount;
        address to;
        bool enacted;
    }
        
    mapping (uint256 => MintingVote) private mintingVotes;

    event MintingProposal(address indexed proposer, address indexed destination, uint256 amount);
    event VoteCast(address indexed voter, uint256 indexed voteIndex);
    event VoteEnacted(address indexed enactor, uint256 indexed voteIndex);
    event LedgerUpdated(address indexed updater, address indexed ledger);
   

    constructor (
        CitizenToken citizenToken_,
        Citizenship citizenship_,
        CitizenDaoLedger ledger_,
        uint256 voteTimeBlocks_,
        address[] memory admins
    ) {
        citizenToken = citizenToken_;
        citizenship = citizenship_;
        voteTimeBlocks = voteTimeBlocks_;
        ledger = ledger_;

        for (uint i = 0; i < admins.length; i++) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);
        }
    }

    // DAO rights
    function isCitizen(address user) public view returns (bool) {
        return citizenship.balanceOf(user) > 0;
    }

    // minting
    function canMint(IAccessControl mintable) public view returns (bool) {
        return mintable.hasRole(Roles.MINTER_ROLE, address(this));
    }

    function canVote(address voter, uint256 index) public view returns (bool) {
        uint256 tokenIndex = citizenship.tokenOfOwnerByIndex(voter, 0);
        return citizenship.balanceOf(voter) > 0 &&
            tokenIndex < mintingVotes[index].votingTokenCutoffIndex &&
            !mintingVotes[index].votes[tokenIndex];
    }

    function createMintingVote(address to, uint256 amount) public returns (uint256) {
        require(isCitizen(_msgSender()), "CitizenDAO: must be a citizen to create a vote");
        require(canMint(citizenToken), "CitizenDAO: contract must have minting rights over token");

        uint256 voteIndex = _voteCounter.current();

        uint256 citizens = citizenship.totalSupply();
        uint256 votesFloor =  citizens >> 1;
        mintingVotes[voteIndex].votesNeeded = votesFloor + citizens % 2;
        mintingVotes[voteIndex].votingTokenCutoffIndex = citizenship.totalSupply();
        mintingVotes[voteIndex].blockCutoff = block.number + voteTimeBlocks;
        mintingVotes[voteIndex].amount = amount;
        mintingVotes[voteIndex].to = to;

        _voteCounter.increment();
        
        emit MintingProposal(_msgSender(), to, amount);

        if(_canWriteToLedger()) {
            ledger.proposal(_msgSender(), voteIndex);
        }
        
        return voteIndex;
    }

    function getMintingVote(uint256 voteIndex)
        public view returns (uint256, uint256, uint256, uint256, uint256, address, bool) {
        require(voteIndex < _voteCounter.current(), "CitizenDAO: invalid vote index");
        return (mintingVotes[voteIndex].totalVotes,
                mintingVotes[voteIndex].votesNeeded,
                mintingVotes[voteIndex].votingTokenCutoffIndex,
                mintingVotes[voteIndex].blockCutoff,
                mintingVotes[voteIndex].amount,
                mintingVotes[voteIndex].to,
                mintingVotes[voteIndex].enacted);
    }

    function castMintingVote(uint256 voteIndex) public returns (bool) {
        require(canVote(_msgSender(), voteIndex), "CitizenDAO: ineligible voter");
        require(mintingVotes[voteIndex].blockCutoff > block.number, "CitizenDAO: Vote expired");
        require(!mintingVotes[voteIndex].enacted, "CitizenDAO: Vote already enacted");
        require(voteIndex < _voteCounter.current(), "CitizenDAO: Invalid Vote Number");

        uint256 tokenId = citizenship.tokenOfOwnerByIndex(_msgSender(), 0);
        mintingVotes[voteIndex].votes[tokenId] = true;
        mintingVotes[voteIndex].totalVotes++;

        emit VoteCast(_msgSender(), voteIndex);
        return true;      
    }

    function enactVote(uint256 voteIndex) public returns (bool) {
        require(isCitizen(_msgSender()), "CitizenDAO: must be a citizen to enact a vote");
        require(mintingVotes[voteIndex].totalVotes >= mintingVotes[voteIndex].votesNeeded,
                "CitizenDAO: Vote not passed");
        require(!mintingVotes[voteIndex].enacted, "CitizenDAO: vote already enacted");

        mintingVotes[voteIndex].enacted = true;
        citizenToken.mint(mintingVotes[voteIndex].to, mintingVotes[voteIndex].amount);

        emit VoteEnacted(_msgSender(), voteIndex);
        if(_canWriteToLedger()) {
            ledger.proposalPassed(voteIndex);
        }
        return true;
    }

    function setLedger(CitizenDaoLedger _ledger) public returns (bool) {
        require(hasRole(Roles.DAO_ADMIN, _msgSender()), "CitizenDAO: must be admin to update ledger");
        ledger = _ledger;
        return true;
    }

    function _canWriteToLedger() internal view returns (bool) {
        return ledger.canWriteToLedger(address(this));
    }
}
