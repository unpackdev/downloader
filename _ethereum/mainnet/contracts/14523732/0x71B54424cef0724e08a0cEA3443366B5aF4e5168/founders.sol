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

    struct FounderProposal {
        uint256 f1Vote;
        uint256 f2Vote;

        bytes32 pDesc;
        fps pState;

        address pFrom;
        address pTargets;
        uint256 pValues;
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

    event ProposalCreated(address indexed _from, uint256 _id, string _value);
    event SwapAddressProposalCreated(address indexed _from, uint256 _id, string _value);
    
    mapping(uint256 => FounderProposal) proposalVotes;
    mapping(uint256 => AddressSwapProposal) addressSwapProposalVotes;

    FounderWallet founderOne;
    FounderWallet founderTwo;
    FounderWallet companyWallet; 
    FounderWallet charityWallet; 
    FounderWallet vestingWalletMoon; //contract address
    FounderWallet vestingWalletSun; //contract address 

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
        addCompanyWallet(
            "CW",          
            payable(address(0x920Bf81087C296D57B4F7f5fCfd96cA71582F066))
           // "CompanyWallet1"
        );
        addCharityWallet(
            "CH",          
            payable(address(0x15411C99E91918Bd963c9B6Ec96fc90b8E7a0dAC)) 
        );
        addMoonWallet(
            "MN",          
            payable(address(0x15411C99E91918Bd963c9B6Ec96fc90b8E7a0dAC)) // charity until vesting deployed
        );
        addSunWallet(
            "SN",          
            payable(address(0x15411C99E91918Bd963c9B6Ec96fc90b8E7a0dAC)) // charity until vesting deployed
        );
        lastPID = 0;
        lastSwapPID = 0;
    }

    function _createAddressSwapProposal(address payable oldAddr, address payable newAddr, bytes32 desc) 
    internal 
    virtual {
        require(oldAddr == founderOne.founderAddress        || 
                oldAddr == founderTwo.founderAddress        || 
                oldAddr == charityWallet.founderAddress     ||
                oldAddr == companyWallet.founderAddress     ||
                oldAddr == vestingWalletMoon.founderAddress ||
                oldAddr == vestingWalletSun.founderAddress  ||
                oldAddr == globals.ADMIN_ADDRESS
        );

        if(!addressSwapProposalVotes[lastSwapPID + 1].exists) {
        } 
        else require(1 == 0);
        addressSwapProposalVotes[++lastSwapPID] = AddressSwapProposal( 0, 0, 
            desc, fps.Queued, oldAddr, newAddr, true, block.timestamp);
        emit SwapAddressProposalCreated(msg.sender, lastSwapPID, "C");
    }

    function _createProposal(address pFrom, address  tgts, uint256 vals, bytes32 desc) 
    internal 
    virtual  {

        if(!proposalVotes[lastPID + 1].exists) {
        } 
        else require(1 == 0);
        proposalVotes[++lastPID] = FounderProposal(0, 0, desc, fps.Queued, pFrom, tgts, vals, true);
        emit ProposalCreated(msg.sender, lastPID, "C");
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

    function sCompanyAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        companyWallet.founderAddress = _newAddress;
    }

    function sMoonAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        vestingWalletMoon.founderAddress = _newAddress;
    }

    function sSunAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        vestingWalletSun.founderAddress = _newAddress;
    }

    function sCharityAddress(address payable _newAddress)
    private
    onlyRole(globals.ADMIN_ROLE) {
        charityWallet.founderAddress = _newAddress;
    }

    function addMoonWallet(
        string memory _fAlias,
        address payable _fAddress) 
    private {
        if (
            (keccak256(bytes(vestingWalletMoon.founderAlias))) != keccak256(bytes("MN"))
        ) {
            vestingWalletMoon = FounderWallet(_fAlias, _fAddress);
        }
    }

    function addSunWallet(
        string memory _fAlias,
        address payable _fAddress) 
    private {
        if (
            (keccak256(bytes(vestingWalletSun.founderAlias))) != keccak256(bytes("SN"))
        ) {
            vestingWalletSun = FounderWallet(_fAlias, _fAddress);
        }
    }

    function addCharityWallet(
        string memory _fAlias,
        address payable _fAddress) 
    private {
        if (
            (keccak256(bytes(charityWallet.founderAlias))) != keccak256(bytes("Z"))
        ) {
            charityWallet = FounderWallet(_fAlias, _fAddress);
        }
    }

    function addCompanyWallet(
        string memory _fAlias,
        address payable _fAddress) 
    private {
        if (
            (keccak256(bytes(companyWallet.founderAlias))) != keccak256(bytes("C"))
        ) {
            companyWallet = FounderWallet(_fAlias, _fAddress);
        }
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
        else if(companyWallet.founderAddress == p.swapOld) {
            companyWallet.founderAddress = p.swapNew;
        }
        else if(charityWallet.founderAddress == p.swapOld) {
            charityWallet.founderAddress = p.swapNew;
        }
        else if(vestingWalletSun.founderAddress == p.swapOld) {
            vestingWalletSun.founderAddress = p.swapNew;
        }
        else if(vestingWalletMoon.founderAddress == p.swapOld) {
            vestingWalletMoon.founderAddress = p.swapNew;
        }
        else if(globals.ADMIN_ADDRESS == p.swapOld)
        {
            _grantRole(globals.UPGRADER_ROLE, p.swapNew);
            _setupRole(globals.ADMIN_ROLE, p.swapNew);
            _setupRole(DEFAULT_ADMIN_ROLE, p.swapNew);
            globals.ADMIN_ADDRESS == p.swapNew;
            _revokeRole(globals.UPGRADER_ROLE, p.swapOld);
            _revokeRole(globals.ADMIN_ROLE, p.swapOld);
            _revokeRole(DEFAULT_ADMIN_ROLE, p.swapOld);         
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

    /*Functions on proposals to move money*/
    function f1VoteOnFundsProposal(
        uint256 vote, uint256 proposalID
        ) internal 
            virtual{

        FounderProposal memory p = proposalVotes[proposalID]; 
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

    function f2VoteOnFundsProposal(uint256 vote, uint256 proposalID) 
    internal 
    virtual {
        FounderProposal memory p = proposalVotes[proposalID]; 
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
        FounderProposal memory p = proposalVotes[proposalID];
        if (p.pState != fps.Succeeded)
            require(1 == 0, "!");
        
        proposalVotes[proposalID].pState = fps.ExecutedByFounders;
        return 1;
    }

    function sFinalState(uint256 proposalID) 
    private {
        FounderProposal memory p = proposalVotes[proposalID]; 
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
        FounderProposal memory p = proposalVotes[proposalID];
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
        FounderProposal memory p = proposalVotes[proposalID];
        return p.pDesc;
    }
}
