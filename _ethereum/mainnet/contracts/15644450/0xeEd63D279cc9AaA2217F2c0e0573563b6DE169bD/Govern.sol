// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./GovernorUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./VotesUpgradeable.sol";
import "./Constant.sol";

contract Govern is
    Initializable, UUPSUpgradeable, GovernorUpgradeable
{

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    address public owner;
    uint public duration;
    uint public quorumThreshold;
    uint public passThreshold;
    address public voteToken;
    mapping(uint256 => ProposalVote) private _proposalVotes;

    modifier onlyOwner {
        require(msg.sender == owner, "Access denied");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        uint _duration,
        uint _quorum,
        uint _passThreshold,
        address _voteToken
    ) external initializer {
        require(_isVotableToken(_voteToken),"Govern Token without voting function");
        require(_owner != address(0),"Owner cannot be empty");
        require(_voteToken != address(0),"VoteToken cannot be empty");

        __Governor_init(_name);

        owner = _owner;
        //13.14s for 1 block
        duration = _duration;
        quorumThreshold = _quorum; //expecting 2 decimals (i.e. 1000 = 10%)
        passThreshold = _passThreshold; //expecting 2 decimals (i.e. 250 = 2.5%)
        voteToken = _voteToken;
    }

    function getProposalVote(uint256 proposalId, uint8 support) external view returns (uint256) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        
        if (support == uint8(VoteType.Against)) {
            return proposalvote.againstVotes;
        } else if (support == uint8(VoteType.For)) {
            return proposalvote.forVotes;
        } else if (support == uint8(VoteType.Abstain)) {
            return proposalvote.abstainVotes;
        } else {
            revert("Governor: invalid value for enum VoteType");
        }
    }

    function votingPeriod() public view override returns (uint256) {
        return duration / Constant.BLOCK_NUMBER_IN_SECOND;
    }

    function votingDelay() public pure override returns (uint256) {
        return 0;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    function COUNTING_MODE() public pure override returns (string memory) {
        return "support=bravo&quorum=for,against";
    }

    function hasVoted(uint256 proposalId, address account) public view override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory // params
    ) internal view override returns (uint256) {
      return VotesUpgradeable(voteToken).getPastVotes(account, blockNumber);
    }

    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return totalPastSupply(blockNumber) * (quorumThreshold / 10000);
    }

    function totalPastSupply(uint256 blockNumber) public view returns (uint256) {
        return VotesUpgradeable(voteToken).getPastTotalSupply(blockNumber);
    }

    function quorumReached(uint256 proposalId) external view returns (bool) {
        return _quorumReached(proposalId);
    }

    function voteSucceeded(uint256 proposalId) external view returns (bool) {
        return _voteSucceeded(proposalId);
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable override returns (uint256) {
        if (targets[0] == address(0)) {
            revert("no content");
        }

        return super.execute(targets, values, calldatas, descriptionHash);
    }

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal override {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(!proposalvote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("Governor: invalid value for enum VoteType");
        }
    }

    function _quorumReached(uint256 proposalId) internal view override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        uint countedVotes = proposalvote.forVotes + proposalvote.againstVotes;

        return quorum(proposalSnapshot(proposalId)) <= countedVotes;
    }

    function _voteSucceeded(uint256 proposalId) internal view override returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        uint _forVotes = proposalvote.forVotes;
        uint totalVotes = _forVotes + proposalvote.againstVotes;
        return totalVotes == 0 ? false : (_forVotes * 100 * 100) >= totalVotes * passThreshold;
    }

    function _isVotableToken(address _voteToken) internal view  returns (bool) {
        try IVotesUpgradeable(_voteToken).getPastTotalSupply( 0 ) {
        } catch {
            return false;
        }

        try IVotesUpgradeable(_voteToken).getPastVotes(address(this), 0 ) {
            return true;
        } catch {
            return false;
        }
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {}

    uint256[50] private __gap;
}