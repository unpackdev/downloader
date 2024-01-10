// SPDX-License-Identifier: LGPL-3.0-or-later
/**
 * @title obscurityDAO
 * @email obscuirtyceo@gmail.com
 * @dev Nov 3, 2020
 * ERC-20 
 * obscurityDAO Copyright and Disclaimer Notice:
 */
pragma solidity ^0.8.7 <0.9.0;

import "./globals.sol";

abstract contract FounderWallets is globals {

    enum fps {
        Active,
        Defeated,
        Succeeded,
        ExecutedByFounders,
        Queued
    }

    struct FounderWallet {
        string founderAlias;
        address payable founderAddress;
    }

    struct FounderETHAmountProposal {
        uint256 f1Vote;
        uint256 f2Vote;

        bytes32 pDesc;
        fps pState;
        uint256 newAmount;
        bool exists;
    }

    struct AddressSwapProposal {
        uint256 f1Vote;
        uint256 f2Vote;

        bytes32 pDesc;
        fps sState;
        address payable swapOld;
        address payable swapNew;
        bool exists;
        uint256 createdTime;
    }

    event ETHAmountProposalCreated(address indexed _from, uint256 _id, string _value);
    event SwapAddressProposalCreated(address indexed _from, uint256 _id, string _value);
    
    mapping(uint256 => FounderETHAmountProposal) proposalVotes;
    mapping(uint256 => AddressSwapProposal) addressSwapProposalVotes;

    FounderWallet founderOne;
    FounderWallet founderTwo;

    uint256 lastPID;
    uint256 lastSwapPID;

    function _founders_init() 
    internal 
    onlyInitializing {
        globals_init();
        addFounderOne(
            "FO",           
            payable(address(0x60A7A4Ce65e314642991C46Bed7C1845588F6cD0))
           // "FounderOne"
        );
        addFounderTwo(
            "FT",
            payable(address(0x6188b15bAE64416d779560D302546e5dE15E5d1E))
           // "FounderTwo"
        );
        lastPID = 0;
        lastSwapPID = 0;
    }

    function _createAddressSwapProposal(address payable oldAddr, address payable newAddr, bytes32 desc) 
    internal 
    virtual {
        require(oldAddr == founderOne.founderAddress        || 
                oldAddr == founderTwo.founderAddress        || 
                oldAddr == globals.ADMIN_ADDRESS
        );

        if(!addressSwapProposalVotes[lastSwapPID + 1].exists) {
        } 
        else require(1 == 0);
        addressSwapProposalVotes[++lastSwapPID] = AddressSwapProposal( 0, 0, 
            desc, fps.Queued, oldAddr, newAddr, true, block.timestamp);
        emit SwapAddressProposalCreated(msg.sender, lastSwapPID, "C");
    }

    function _createETHAmountProposal(uint256 newAmount, bytes32 desc) 
    internal 
    virtual  {

        if(!proposalVotes[lastPID + 1].exists) {
        } 
        else require(1 == 0);
        proposalVotes[++lastPID] = FounderETHAmountProposal(0, 0,
         desc, fps.Queued, newAmount, true);
        emit ETHAmountProposalCreated(msg.sender, lastPID, "C");
    }

    function sFOneAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        founderOne.founderAddress = _newAddress;
    }

    function sFTwoAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        founderOne.founderAddress = _newAddress;
    }

    function addFounderOne(
        string memory _fAlias,
        address payable _fAddress)
    private {
        if (
            (keccak256(bytes(founderOne.founderAlias))) != keccak256(bytes("O"))
        ) {
            founderOne = FounderWallet(_fAlias, _fAddress);
        }
    }

    function addFounderTwo(
        string memory _fAlias,
        address payable _fAddress)
    private {
        if (
            (keccak256(bytes(founderTwo.founderAlias))) != keccak256(bytes("T"))
        ) {
            founderTwo = FounderWallet(_fAlias, _fAddress);
        }
    }
    /*Functions on proposals to change address*/
    function f1VoteOnSwapProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {

        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated) {
            require(1 == 0);
        }
        if(p.sState == fps.Queued)
            addressSwapProposalVotes[proposalID].sState = fps.Active;
        
        if(vote != 1) {
            addressSwapProposalVotes[proposalID].f1Vote = vote;
            addressSwapProposalVotes[proposalID].sState = fps.Defeated;
            require(1 == 0); 
        }

        if(vote == 1) {
            addressSwapProposalVotes[proposalID].f1Vote = vote;
        }
    }

    function f2VoteOnSwapProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {

        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated) {
            require(1 == 0);
        }
        if(p.sState == fps.Queued)
            addressSwapProposalVotes[proposalID].sState = fps.Active;
        
        if(vote != 1)
        {
            addressSwapProposalVotes[proposalID].f2Vote = vote;
            addressSwapProposalVotes[proposalID].sState = fps.Defeated;
            require(1 == 0);
        }

        if(vote == 1)
        {
            addressSwapProposalVotes[proposalID].f2Vote = vote;
        }
    }

    function addressSwapExecution(uint256 proposalID) 
    internal
    virtual {
        addrSwapFinalState(proposalID);
        
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        if (p.sState != fps.Succeeded)
            require(1 == 0, "0");

        if (founderOne.founderAddress == p.swapOld) {
            founderOne.founderAddress = p.swapNew;
            _revokeRole(globals.PAUSER_ROLE, p.swapOld);
            _grantRole(globals.PAUSER_ROLE, p.swapNew);
        }
        else if(founderTwo.founderAddress == p.swapOld) {
            founderTwo.founderAddress = p.swapNew;
            _revokeRole(globals.PAUSER_ROLE, p.swapOld);
            _grantRole(globals.PAUSER_ROLE, p.swapNew);
        }
        else if(globals.ADMIN_ADDRESS == p.swapOld)
        {
            _grantRole(globals.UPGRADER_ROLE, p.swapNew);
            _grantRole(globals.ADMIN_ROLE, p.swapNew);
            _grantRole(DEFAULT_ADMIN_ROLE, p.swapNew);
            globals.ADMIN_ADDRESS == p.swapNew;
            _revokeRole(globals.UPGRADER_ROLE, globals.ADMIN_ADDRESS);
            _revokeRole(globals.ADMIN_ROLE, globals.ADMIN_ADDRESS);
            _revokeRole(DEFAULT_ADMIN_ROLE, globals.ADMIN_ADDRESS);           
        }
        
        addressSwapProposalVotes[proposalID].sState = fps.ExecutedByFounders;
    }

    function addrSwapFinalState(uint256 proposalID) 
    private {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID]; 
        if(p.sState == fps.Defeated)
        {
            require(1 == 0, "1");
        }

        if (block.timestamp < p.createdTime + 30 days) {
            require(p.f1Vote + p.f2Vote == 2, "N");
            {
                addressSwapProposalVotes[proposalID].sState = fps.Succeeded;
            }
        }
        else {
            addressSwapProposalVotes[proposalID].sState = fps.Succeeded;
        }
    }

    function gPSwapState(uint256 proposalID) 
    public 
    view 
    returns (uint256) {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        if (p.sState == fps.Active)
            return 1;
        else if (p.sState == fps.Defeated)
            return 4;
        else if (p.sState == fps.Succeeded)
            return 2;
        else if (p.sState == fps.ExecutedByFounders)
            return 3;
        else 
            return 0;
    }

    function gPSwapDesc(uint256 proposalID) 
    public 
    view 
    returns (bytes32) {
        AddressSwapProposal memory p = addressSwapProposalVotes[proposalID];
        return p.pDesc;
    }

    /*Functions on proposals to change amount for current phase*/
    function f1VoteOnETHAmountChangeProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated)
        {
             require(1 == 0, "C");
        }
        if(p.pState == fps.Queued)
            p.pState = fps.Active;
        
        if(vote != 1)
        {
            p.f1Vote = vote;
            p.pState = fps.Defeated;
        }

        if(vote == 1)
        {
            p.f1Vote = vote;
        }
        proposalVotes[proposalID] = p;
    }

    function f2VoteOnETHAmountChangeProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated)
        {
            require(1 == 0);
        }
        if(p.pState == fps.Queued)
            proposalVotes[proposalID].pState = fps.Active;
        
        if(vote != 1)
        {
            proposalVotes[proposalID].f2Vote = vote;
            proposalVotes[proposalID].pState = fps.Defeated;
        }

        if(vote == 1)
        {
            proposalVotes[proposalID].f2Vote = vote;
        }
    }

    function founderExecution(uint256 proposalID) 
    internal
    virtual returns (uint256) {
        sFinalState(proposalID);
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        if (p.pState != fps.Succeeded)
            require(1 == 0, "!");
        
        proposalVotes[proposalID].pState = fps.ExecutedByFounders;
        return 1;
    }

    function sFinalState(uint256 proposalID) 
    private {
        FounderETHAmountProposal memory p = proposalVotes[proposalID]; 
        if(p.pState == fps.Defeated) {
            require(0 == 1);
        }
        else{
            require(p.f1Vote + p.f2Vote == 2, "N");
            proposalVotes[proposalID].pState = fps.Succeeded;
        }
    }

    function gPState(uint256 proposalID) 
    public 
    view returns (uint256) {
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        if (p.pState == fps.Active)
            return 1;
        else if (p.pState == fps.Defeated)
            return 4;
        else if (p.pState == fps.Succeeded)
            return 2;
        else if(p.pState == fps.ExecutedByFounders)
            return 3;
        else 
            return 0;
    }

    function gPDesc(uint256 proposalID) 
    public 
    view returns (bytes32) {
        FounderETHAmountProposal memory p = proposalVotes[proposalID];
        return p.pDesc;
    }
}
