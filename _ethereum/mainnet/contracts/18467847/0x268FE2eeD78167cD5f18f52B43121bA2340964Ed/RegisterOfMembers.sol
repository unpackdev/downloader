// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";

import "./AccessControl.sol";

contract RegisterOfMembers is IRegisterOfMembers, AccessControl {
    // using EnumerableSet for EnumerableSet.Bytes32Set;
    using MembersRepo for MembersRepo.Repo;
    using TopChain for TopChain.Chain;

    MembersRepo.Repo private _repo;

    //##################
    //##   Modifier   ##
    //##################

    modifier onlyROS() {
        require(msg.sender == address(_gk.getROS()),
            "ROM.onlyROS: not");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################

    // ---- Options Setting ----

    function setMaxQtyOfMembers(uint max) external onlyKeeper {
        _repo.chain.setMaxQtyOfMembers(max);
        emit SetMaxQtyOfMembers(max);
    }

    function setMinVoteRatioOnChain(uint min) external onlyKeeper {
        _repo.chain.setMinVoteRatioOnChain(min);
        emit SetMinVoteRatioOnChain(min);
    }

    function setVoteBase(bool _basedOnPar) external onlyKeeper {
        if (_repo.setVoteBase(_basedOnPar)) 
            emit SetVoteBase(_basedOnPar);
    }

    function capIncrease(
        uint votingWeight, 
        uint paid, 
        uint par, 
        bool isIncrease
    ) external onlyROS {

        _repo.increaseAmtOfCap(votingWeight, paid, par, isIncrease);

        if (isIncrease) emit CapIncrease(votingWeight, paid, par);
        else emit CapDecrease(votingWeight, paid, par);
    }

    function addMember(uint256 acct) external onlyROS {
        if (_repo.addMember(acct))
            emit AddMember(acct, _repo.chain.qtyOfMembers());
    }

    function addShareToMember(
        SharesRepo.Share memory share
    ) external onlyROS {

        _repo.addShareToMember(share.head);

        _repo.increaseAmtOfMember(
            share.head.shareholder, 
            share.head.votingWeight, 
            share.body.paid, 
            share.body.par, 
            share.body.cleanPaid, 
            true
        );
        
        emit AddShareToMember(share.head.seqOfShare, share.head.shareholder);
    }

    function removeShareFromMember(
        SharesRepo.Share memory share
    ) external onlyROS {

        _repo.increaseAmtOfMember(
            share.head.shareholder, 
            share.head.votingWeight, 
            share.body.paid, 
            share.body.par, 
            share.body.cleanPaid, 
            false
        );

        _repo.removeShareFromMember(share.head);

        if (_repo.qtyOfSharesInHand(share.head.shareholder) == 0) 
            _repo.delMember(share.head.shareholder);

        emit RemoveShareFromMember(share.head.seqOfShare, share.head.shareholder);        
    }

    function increaseAmtOfMember(
        uint acct,
        uint votingWeight,
        uint deltaPaid,
        uint deltaPar,
        uint deltaClean,
        bool isIncrease
    ) public onlyROS {

        _repo.increaseAmtOfMember(
            acct,
            votingWeight,
            deltaPaid,
            deltaPar,
            deltaClean,
            isIncrease
        );

        emit ChangeAmtOfMember(
            acct,
            deltaPaid,
            deltaPar,
            deltaClean,
            isIncrease
        );
    }

    function addMemberToGroup(uint acct, uint root)
        external
        onlyKeeper
    {
        _repo.chain.top2Sub(acct, root);
        emit AddMemberToGroup(acct, root);
    }

    function removeMemberFromGroup(uint256 acct)
        external
        onlyKeeper
    {
        uint root = _repo.chain.rootOf(acct);
        uint256 next = _repo.chain.nextNode(acct);

        _repo.chain.sub2Top(acct);
        emit RemoveMemberFromGroup(acct, root);
        if (acct == root) emit ChangeGroupRep(root, next);
    }

    // ##################
    // ##   查询接口    ##
    // ##################

    // ---- membersList ----

    function isMember(uint256 acct) external view returns (bool) {
        return _repo.isMember(acct);
    }

    function qtyOfMembers() external view returns (uint) {
        return _repo.qtyOfMembers();
    }

    function membersList() external view returns (uint256[] memory) {
        return _repo.membersList();
    }

    function sortedMembersList() external view returns (uint256[] memory) {
        return _repo.chain.sortedMembersList();
    }

    function qtyOfTopMembers() external view returns (uint) {
        return _repo.chain.qtyOfTopMembers();
    }

    function topMembersList() external view returns (uint[] memory) {
        return _repo.chain.topMembersList();
    }

    // ---- Cap & Equity ----

    function ownersEquity() 
        external view 
        returns(Checkpoints.Checkpoint memory) 
    {
        return _repo.ownersEquity();
    }

    function capAtDate(uint date)
        external view
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.capAtDate(date); 
    }

   function equityOfMember(uint256 acct)
        external view
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.equityOfMember(acct);
    }

   function equityAtDate(uint256 acct, uint date)
        external view
        returns (Checkpoints.Checkpoint memory)
    {
        return _repo.equityAtDate(acct, date);
    }

    function votesInHand(uint256 acct)
        external
        view
        returns (uint64)
    {
        require(_repo.isMember(acct), "ROM.votesInHand: not member");
        return _repo.chain.nodes[acct].amt;
    }

    function votesAtDate(uint256 acct, uint date)
        external view
        returns (uint64)
    {
        return _repo.votesAtDate(acct, date);
    }

    function votesHistory(uint acct)
        external view 
        returns (Checkpoints.Checkpoint[] memory)
    {
        return _repo.votesHistory(acct);
    }

    // ---- ShareNum ----

    function qtyOfSharesInHand(uint acct)
        external view returns(uint)
    {
        return _repo.qtyOfSharesInHand(acct);
    }
    
    function sharesInHand(uint256 acct)
        external view
        returns (uint[] memory)
    {
        return _repo.sharesInHand(acct);
    }

    // ---- Class ---- 

    function qtyOfSharesInClass(uint acct, uint class)
        external view returns(uint)
    {
        return _repo.qtyOfSharesInClass(acct, class);
    }

    function sharesInClass(uint256 acct, uint class)
        external view
        returns (uint[] memory)
    {
        return _repo.sharesInClass(acct, class);
    }

    function isClassMember(uint256 acct, uint class)
        external view returns(bool)
    {
        return _repo.isClassMember(acct, class);
    }

    function classesBelonged(uint acct)
        external view returns(uint[] memory)
    {
        return _repo.classesBelonged(acct);
    }

    function qtyOfClassMember(uint class)
        external view returns(uint) 
    {
        return _repo.qtyOfClassMember(class);
    }

    function getMembersOfClass(uint class)
        external view returns(uint256[] memory)
    {
        return _repo.getMembersOfClass(class);
    }

    // ---- TopChain ----

    function basedOnPar() external view returns (bool) {
        return _repo.chain.basedOnPar();
    }

    function maxQtyOfMembers() external view returns (uint32) {
        return _repo.chain.maxQtyOfMembers();
    }

    function minVoteRatioOnChain() external view returns (uint32) {
        return _repo.chain.minVoteRatioOnChain();
    }

    function totalVotes() external view returns (uint64) {
        return _repo.chain.totalVotes();
    }

    function controllor() external view returns (uint40) {
        return _repo.chain.head();
    }

    function tailOfChain() external view returns (uint40) {
        return _repo.chain.tail();
    }

    function headOfQueue() external view returns (uint40) {
        return _repo.chain.headOfQueue();
    }

    function tailOfQueue() external view returns (uint40) {
        return _repo.chain.tailOfQueue();
    }

    // ==== group ====

    function groupRep(uint256 acct) external view returns (uint40) {
        return _repo.chain.rootOf(acct);
    }

    function votesOfGroup(uint256 acct) external view returns (uint64) {
        return _repo.chain.votesOfGroup(acct);
    }

    function deepOfGroup(uint256 acct) external view returns (uint256) {
        return _repo.chain.deepOfBranch(acct);
    }

    function membersOfGroup(uint256 acct)
        external
        view
        returns (uint256[] memory)
    {
        return _repo.chain.membersOfGroup(acct);
    }

    function qtyOfGroupsOnChain() external view returns (uint32) {
        return _repo.chain.qtyOfBranches();
    }

    function qtyOfGroups() external view returns (uint256) {
        return _repo.chain.qtyOfGroups();
    }

    function affiliated(uint256 acct1, uint256 acct2)
        external
        view
        returns (bool)
    {
        return _repo.chain.affiliated(acct1, acct2);
    }

    // ==== snapshot ====

    function getSnapshot() external view returns (TopChain.Node[] memory, TopChain.Para memory) {
        return _repo.chain.getSnapshot();
    }
}
