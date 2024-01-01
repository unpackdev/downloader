// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfPledges.sol";

import "./AccessControl.sol";

contract RegisterOfPledges is IRegisterOfPledges, AccessControl {
    using PledgesRepo for PledgesRepo.Repo;
    using PledgesRepo for PledgesRepo.Pledge;

    PledgesRepo.Repo private _repo;

    //##################
    //##  Write I/O  ##
    //##################

    function createPledge(
        bytes32 snOfPld,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external onlyDK returns(PledgesRepo.Head memory head){
        head = _repo.createPledge(
            snOfPld,
            paid,
            par,
            guaranteedAmt,
            execDays
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            head.creditor,
            paid,
            par
        );
    }

    function issuePledge(
        PledgesRepo.Head memory head,
        uint paid,
        uint par,
        uint guaranteedAmt,
        uint execDays
    ) external onlyKeeper returns(PledgesRepo.Head memory regHead)
    {
        regHead = _repo.issuePledge(
            head, 
            paid,
            par,
            guaranteedAmt,
            execDays
        );

        emit CreatePledge(
            head.seqOfShare,
            head.seqOfPld,
            head.creditor,
            paid,
            par
        );
    }

    function regPledge(
        PledgesRepo.Pledge memory pld
    ) external onlyKeeper returns(PledgesRepo.Head memory head){
        head = _repo.regPledge(pld);

        emit CreatePledge(
            pld.head.seqOfShare, 
            head.seqOfPld, 
            pld.head.creditor,
            pld.body.paid, 
            pld.body.par 
        );
    }

    // ==== Transfer Pledge ====

    function transferPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint buyer,
        uint amt,
        uint caller
    ) external onlyKeeper returns (PledgesRepo.Pledge memory newPld)
    {
        require(buyer > 0, "ROP.transferPld: zero buyer");

        newPld = _repo.splitPledge(seqOfShare, seqOfPld, buyer, amt, caller);

        emit TransferPledge(
            newPld.head.seqOfShare, 
            seqOfPld,
            newPld.head.seqOfPld, 
            newPld.head.creditor,
            newPld.body.paid, 
            newPld.body.par 
        );
    }

    // ==== Update Pledge ====

    function refundDebt(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint amt,
        uint caller
    ) external onlyKeeper returns (PledgesRepo.Pledge memory newPld)
    {
        newPld = _repo.splitPledge(seqOfShare, seqOfPld, 0, amt, caller);

        emit RefundDebt(seqOfShare, seqOfPld, amt);
    }

    function extendPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        uint extDays,
        uint caller
    ) external onlyKeeper {
        _repo.pledges[seqOfShare][seqOfPld].extendPledge(extDays, caller);
        emit ExtendPledge(seqOfShare, seqOfPld, extDays);
    }

    // ==== Lock/Release/Exec/Revoke ====

    function lockPledge(
        uint256 seqOfShare,
        uint256 seqOfPld,
        bytes32 hashLock,
        uint caller
    ) external onlyKeeper {
        _repo.pledges[seqOfShare][seqOfPld].lockPledge(hashLock, caller);
        emit LockPledge(seqOfShare, seqOfPld, hashLock);
    }

    function releasePledge(
        uint256 seqOfShare, 
        uint256 seqOfPld, 
        string memory hashKey
    ) external onlyKeeper returns (uint64) {
        PledgesRepo.Pledge storage pld = _repo.pledges[seqOfShare][seqOfPld];
        pld.releasePledge(hashKey);   
        emit ReleasePledge(seqOfShare, seqOfPld, hashKey);
        return pld.body.paid;
    }

    function execPledge(uint256 seqOfShare, uint256 seqOfPld, uint caller)
        external onlyKeeper 
    {
        _repo.pledges[seqOfShare][seqOfPld].execPledge(caller);
        emit ExecPledge(seqOfShare, seqOfPld);
    }

    function revokePledge(uint256 seqOfShare, uint256 seqOfPld, uint caller)
        external onlyKeeper {
        _repo.pledges[seqOfShare][seqOfPld].revokePledge(caller);
        emit RevokePledge(seqOfShare, seqOfPld);
    }

    //##################
    //##    读接口    ##
    //##################

    function counterOfPledges(uint256 seqOfShare) 
        external view returns (uint16) 
    {
        return _repo.counterOfPld(seqOfShare);
    }

    function isPledge(uint256 seqOfShare, uint256 seqOfPledge) 
        external view returns (bool) 
    {
        return _repo.isPledge(seqOfShare, seqOfPledge);
    }

    function getSNList() external view returns(bytes32[] memory)
    {
        return _repo.getSNList();
    }

    function getPledge(uint256 seqOfShare, uint256 seqOfPld)
        external view returns (PledgesRepo.Pledge memory)
    {
        return _repo.getPledge(seqOfShare, seqOfPld);
    }

    function getPledgesOfShare(uint256 seqOfShare) 
        external view returns (PledgesRepo.Pledge[] memory) 
    {
        return _repo.getPledgesOfShare(seqOfShare);
    }

    function getAllPledges() external view 
        returns (PledgesRepo.Pledge[] memory)
    {
        return _repo.getAllPledges();
    }

}
