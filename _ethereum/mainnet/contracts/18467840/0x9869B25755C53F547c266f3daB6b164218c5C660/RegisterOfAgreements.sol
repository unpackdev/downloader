// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfAgreements.sol";

import "./FilesFolder.sol";

contract RegisterOfAgreements is IRegisterOfAgreements, FilesFolder {
    using DTClaims for DTClaims.Claims;
    using DTClaims for DTClaims.Head;
    using FRClaims for FRClaims.Claims;
    using FilesRepo for FilesRepo.Repo;
    using TopChain for TopChain.Chain;

    // ia => frClaims
    mapping(address => FRClaims.Claims) private _frClaims;
    // ia => dtClaims
    mapping(address => DTClaims.Claims) private _dtClaims;
    // ia => mockResults
    mapping(address => TopChain.Chain) private _mockOfIA;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== FirstRefusal ====

    function claimFirstRefusal(
        address ia,
        uint256 seqOfDeal,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper {
        require(block.timestamp < _repo.frExecDeadline(ia),
            "ROA.claimFR: missed frExecDeadline");
        _frClaims[ia].claimFirstRefusal(seqOfDeal, caller, sigHash);
        emit ClaimFirstRefusal(ia, seqOfDeal, caller);
    }

    function computeFirstRefusal(
        address ia,
        uint256 seqOfDeal
    ) external onlyKeeper returns (FRClaims.Claim[] memory output) {
        require(block.timestamp >= _repo.frExecDeadline(ia),
            "ROA.computeFR: not reached frExecDeadline");
        output = _frClaims[ia].computeFirstRefusal(seqOfDeal, _gk.getROM());
        emit ComputeFirstRefusal(ia, seqOfDeal);
    }

    // ==== DragAlong & TagAlong ====

    function execAlongRight(
        address ia,
        bool dragAlong,
        uint256 seqOfDeal,
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint256 caller,
        bytes32 sigHash
    ) external onlyKeeper {
        require(block.timestamp >= _repo.frExecDeadline(ia),
            "ROA.execDT: not reached frExecDeadline");
        require(block.timestamp < _repo.dtExecDeadline(ia),
            "ROA.execDT: missed dtExecDeadline");

        _dtClaims[ia].execAlongRight(dragAlong, seqOfDeal, seqOfShare, paid, par, caller, sigHash);

        DTClaims.Head memory head = DTClaims.Head({
            seqOfDeal: uint16(seqOfDeal),
            dragAlong: dragAlong,
            seqOfShare: uint32(seqOfShare),
            paid: uint64(paid),
            par: uint64(par),
            caller: uint40(caller),
            para: 0,
            argu: 0
        });

        emit ExecAlongRight(ia, head.codifyHead(), sigHash);
    }

    function acceptAlongClaims(
        address ia, 
        uint seqOfDeal
    ) external onlyKeeper returns(DTClaims.Claim[] memory) {
        require(block.timestamp >= _repo.dtExecDeadline(ia),
            "ROA.execDT: not reached frExecDeadline");
        // require(block.timestamp < _repo.terminateStartpoint(ia),
        //     "ROA.execDT: missed dtExecDeadline");
        
        emit AcceptAlongClaims(ia, seqOfDeal);
        return _dtClaims[ia].acceptAlongClaims(seqOfDeal);
    }

    // ==== Mock ====

    function createMockOfIA(address ia) external onlyKeeper {
        if (_mockOfIA[ia].qtyOfMembers() == 0) {
            (TopChain.Node[] memory list, TopChain.Para memory para) = 
                _gk.getROM().getSnapshot();
            _mockOfIA[ia].restoreChain(list, para);
            _mockOfIA[ia].mockDealsOfIA(IInvestmentAgreement(ia));
        }
    }

    function mockDealOfSell(
        address ia, 
        uint seller, 
        uint amount
    ) external onlyKeeper {
        _mockOfIA[ia].mockDealOfSell(seller, amount);
    }

    function mockDealOfBuy(
        address ia, 
        uint buyer, 
        uint groupRep, 
        uint amount
    ) external{
        _mockOfIA[ia].mockDealOfBuy(buyer, groupRep, amount);
    }
    
    //###############
    //##  Read I/O ##
    //###############

    // ==== FR Claims ====

    function hasFRClaims(address ia, uint seqOfDeal) external view returns (bool) {
        return _frClaims[ia].isDeal(seqOfDeal);
    }

    function isFRClaimer(address ia, uint256 acct) external view returns (bool)
    {
        return _frClaims[ia].isClaimer(acct);
    }

    function getSubjectDealsOfFR(address ia) external view returns(uint[] memory) {
        return _frClaims[ia].getDeals();
    }

    function getFRClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(FRClaims.Claim[] memory) 
    {
        return _frClaims[ia].getClaimsOfDeal(seqOfDeal);
    }

    function allFRClaimsAccepted(address ia) external view returns (bool) {
        return _frClaims[ia].allAccepted();
    }    

    // ==== DT Claims ====

    function hasDTClaims(address ia, uint256 seqOfDeal) 
        public view returns(bool)
    {
        return _dtClaims[ia].hasClaim(seqOfDeal);
    }

    function getSubjectDealsOfDT(address ia) 
        public view returns(uint256[] memory)
    {
        return _dtClaims[ia].getDeals();
    }

    function getDTClaimsOfDeal(address ia, uint256 seqOfDeal)
        external view returns(DTClaims.Claim[] memory)
    {
        return _dtClaims[ia].getClaimsOfDeal(seqOfDeal);
    }

    function getDTClaimForShare(address ia, uint256 seqOfDeal, uint256 seqOfShare)
        external view returns(DTClaims.Claim memory)
    {
        return _dtClaims[ia].getClaimForShare(seqOfDeal, seqOfShare);
    }

    function allDTClaimsAccepted(address ia) external view returns(bool) {
        return _dtClaims[ia].allAccepted();
    }

    // ==== Mock Results ====

    function mockResultsOfIA(address ia)
        external view
        returns (uint40 controllor, uint16 ratio) 
    {
        TopChain.Chain storage mock = _mockOfIA[ia];

        controllor = mock.head();
        ratio = uint16 (mock.votesOfGroup(controllor) / mock.totalVotes());
    }

    function mockResultsOfAcct(address ia, uint256 acct)
        external view
        returns (uint40 groupRep, uint16 ratio) 
    {
        TopChain.Chain storage mock = _mockOfIA[ia];

        groupRep = mock.rootOf(acct);
        ratio = uint16 (mock.votesOfGroup(groupRep) / mock.totalVotes());
    }

    // ==== allClaimsAccepted ====

    function allClaimsAccepted(address ia) external view returns(bool) {
        return (_dtClaims[ia].allAccepted() && _frClaims[ia].allAccepted());
    }
}
