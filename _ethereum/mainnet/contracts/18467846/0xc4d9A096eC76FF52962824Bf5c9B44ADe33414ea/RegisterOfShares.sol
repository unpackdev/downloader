// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfShares.sol";
import "./AccessControl.sol";

contract RegisterOfShares is IRegisterOfShares, AccessControl {
    using LockersRepo for LockersRepo.Repo;
    using LockersRepo for bytes32;
    using SharesRepo for SharesRepo.Repo;
    using SharesRepo for SharesRepo.Share;
    using SharesRepo for SharesRepo.Head;
    using SharesRepo for uint256;

    SharesRepo.Repo private _repo;
    LockersRepo.Repo private _lockers;

    //##################
    //##  Write I/O  ##
    //##################

    // ==== IssueShare ====

    function issueShare(
        bytes32 shareNumber, 
        uint payInDeadline, 
        uint paid, 
        uint par
    ) external onlyKeeper {

        SharesRepo.Share memory share =
            SharesRepo.createShare(shareNumber, payInDeadline, paid, par);

        addShare(share);
    }

    function addShare(
        SharesRepo.Share memory share
    ) public onlyKeeper {

        IRegisterOfMembers _rom = _gk.getROM();

        share = _repo.addShare(share);
        _repo.increaseEquityOfClass(
            true,
            share.head.class,
            share.body.paid,
            share.body.par,
            0
        );

        _rom.addMember(share.head.shareholder);
        _rom.capIncrease(
            share.head.votingWeight,
            share.body.paid,
            share.body.par,
            true
        );
        _rom.addShareToMember(share);

        emit IssueShare(
            share.head.codifyHead(), 
            share.body.paid, 
            share.body.par
        );
    }

    // ==== PayInCapital ====

    function setPayInAmt(
        uint seqOfShare, 
        uint amt, 
        uint expireDate, 
        bytes32 hashLock
    ) external onlyDK {

        SharesRepo.Share storage share = 
            _repo.shares[seqOfShare];

        LockersRepo.Head memory head = 
            LockersRepo.Head({
                from: share.head.seqOfShare,
                to: share.head.shareholder,
                expireDate: uint48(expireDate),
                value: uint128(amt)
            });

        _lockers.lockPoints(head, hashLock);

        emit SetPayInAmt(LockersRepo.codifyHead(head), hashLock);
    }

    function requestPaidInCapital(
        bytes32 hashLock, 
        string memory hashKey
    ) external onlyDK {

        LockersRepo.Head memory head = 
            _lockers.pickupPoints(hashLock, hashKey, 0);

        if (head.value > 0) {
 
            SharesRepo.Share storage share = 
                _repo.shares[head.from];

            _payInCapital(share, head.value);
        }
    }

    function withdrawPayInAmt(
        bytes32 hashLock, 
        uint seqOfShare
    ) external onlyDK {

        LockersRepo.Head memory head = 
            _lockers.withdrawDeposit(hashLock, seqOfShare);

        emit WithdrawPayInAmt(head.from, head.value);
    }

    function payInCapital(
        uint seqOfShare, 
        uint amt
    ) external onlyDK {

        SharesRepo.Share storage share = 
            _repo.shares[seqOfShare];

        _payInCapital(share, amt);
    }

    // ==== TransferShare ====

    function transferShare(
        uint256 seqOfShare,
        uint paid,
        uint par,
        uint to,
        uint priceOfPaid,
        uint priceOfPar
    ) external onlyKeeper {

        IRegisterOfMembers _rom = _gk.getROM();

        SharesRepo.Share storage share = _repo.shares[seqOfShare];

        require(share.head.shareholder != to,
            "ROS.transferShare: self deal");

        SharesRepo.Share memory newShare;

        newShare.head = SharesRepo.Head({
            seqOfShare: 0,
            preSeq: share.head.seqOfShare,
            class: share.head.class,
            issueDate: 0,
            shareholder: uint40(to),
            priceOfPaid: uint32(priceOfPaid),
            priceOfPar: uint32(priceOfPar),
            votingWeight: share.head.votingWeight,
            argu: 0
        });

        newShare.body = SharesRepo.Body({
            payInDeadline: share.body.payInDeadline,
            paid: uint64(paid),
            par: uint64(par),
            cleanPaid: uint64(paid),
            state: 0,
            para: 0
        });        

        _decreaseShareAmt(share, paid, par);

        _rom.addMember(to);

        newShare = _repo.regShare(newShare);

        _rom.addShareToMember(newShare);
    }

    // ==== DecreaseCapital ====

    function decreaseCapital(
        uint256 seqOfShare,
        uint paid,
        uint par
    ) external onlyDK {
        
        SharesRepo.Share storage share = 
            _repo.shares[seqOfShare];

        _repo.increaseEquityOfClass(
            false,
            share.head.class,
            paid,
            par,
            0
        );

        _gk.getROM().capIncrease(
            share.head.votingWeight,            
            paid, 
            par,
            false
        );

        _decreaseShareAmt(share, paid, par);
    }

    // ==== cleanAmt ====

    function decreaseCleanPaid(
        uint256 seqOfShare, 
        uint paid
    ) external {

        require(msg.sender == address(_gk.getROP()) ||
            _gk.isKeeper(msg.sender), 
            "ROS.decrClean: access denied");

        _repo.increaseCleanPaid(
            false,
            seqOfShare,
            paid
        );

        SharesRepo.Share storage share = 
            _repo.shares[seqOfShare];

        _gk.getROM().increaseAmtOfMember(
            share.head.shareholder, 
            share.head.votingWeight, 
            0, 
            0, 
            paid, 
            false
        );

        emit DecreaseCleanPaid(seqOfShare, paid);
    }

    function increaseCleanPaid(
        uint256 seqOfShare, 
        uint paid
    ) external {

        require(msg.sender == address(_gk.getROP()) ||
            _gk.isKeeper(msg.sender), "ROS.DCA: neither keeper nor ROP");

        _repo.increaseCleanPaid(
            true,
            seqOfShare,
            paid
        );

        SharesRepo.Share storage share = 
            _repo.shares[seqOfShare];

        _gk.getROM().increaseAmtOfMember(
            share.head.shareholder, 
            share.head.votingWeight, 
            0, 
            0, 
            paid, 
            true
        );

        emit IncreaseCleanPaid(seqOfShare, paid);
    }

    // ==== State & PaidInDeadline ====

    // function updateStateOfShare(uint256 seqOfShare, uint state)
    //     external onlyDK 
    // {
    //     emit UpdateStateOfShare(seqOfShare, state);
    //     _repo.shares[seqOfShare].body.state = uint8(state);
    // }

    function updatePriceOfPaid(
        uint seqOfShare,
        uint newPrice
    ) external onlyKeeper {
        _repo.updatePriceOfPaid(seqOfShare, newPrice);
        emit UpdatePriceOfPaid(seqOfShare, newPrice);
    }

    function updatePaidInDeadline(
        uint256 seqOfShare, 
        uint deadline
    ) external onlyDK {

        _repo.updatePayInDeadline(seqOfShare, deadline);

        emit UpdatePaidInDeadline(seqOfShare, deadline);
    }

    // ==== EquityOfClass ====

    function increaseEquityOfClass(
        bool isIncrease,
        uint classOfShare,
        uint deltaPaid,
        uint deltaPar,
        uint deltaCleanPaid
    ) external onlyKeeper {
        _repo.increaseEquityOfClass(
            isIncrease,
            classOfShare,
            deltaPaid,
            deltaPar,
            deltaCleanPaid
        );

        uint amt = (deltaPaid << 128) + uint128(deltaPar << 64) + uint64(deltaCleanPaid);

        emit IncreaseEquityOfClass(isIncrease, classOfShare, amt);
    }



    // ==== private funcs ====

    function _payInCapital(
        SharesRepo.Share storage share, 
        uint amount
    ) private {

        IRegisterOfMembers _rom = _gk.getROM();

        _repo.payInCapital(share.head.seqOfShare, amount);
        _repo.increaseEquityOfClass(
            true,
            share.head.class,
            amount,
            0,
            0
        );

        _rom.capIncrease(
            share.head.votingWeight,
            amount, 
            0,
            true
        );

        _rom.increaseAmtOfMember(
            share.head.shareholder, 
            share.head.votingWeight, 
            amount, 
            0, 
            amount, 
            true
        );

        emit PayInCapital(share.head.seqOfShare, amount);
    }

    function _decreaseShareAmt(
        SharesRepo.Share storage share, 
        uint paid, 
        uint par
    ) private {

        IRegisterOfMembers _rom = _gk.getROM();

        if (par == share.body.par) {

            _rom.removeShareFromMember(share);

            emit DeregisterShare(share.head.seqOfShare);

        } else {

            _rom.increaseAmtOfMember(
                share.head.shareholder,
                share.head.votingWeight,
                paid,
                par,
                paid,
                false
            );

            emit SubAmountFromShare(share.head.seqOfShare, paid, par);
        }

        _repo.subAmtFromShare(share.head.seqOfShare, paid, par);
    }

    // #################
    // ##   查询接口   ##
    // #################

    function counterOfShares() external view returns (uint32) {
        return _repo.counterOfShares();
    }

    function counterOfClasses() external view returns (uint16) {
        return _repo.counterOfClasses();
    }

    // ==== SharesRepo ====

    function isShare(
        uint256 seqOfShare
    ) external view returns (bool) {
        return _repo.isShare(seqOfShare);
    }

    function getShare(
        uint256 seqOfShare
    ) external view returns (
        SharesRepo.Share memory
    ) {
        return _repo.getShare(seqOfShare);
    }

    function getQtyOfShares() external view returns (uint) {
        return _repo.getQtyOfShares();
    }

    function getSeqListOfShares() external view returns (uint[] memory) {
        return _repo.getSeqListOfShares();
    }

    function getSharesList() external view returns (SharesRepo.Share[] memory) {
        return _repo.getSharesList();
    }

    // ---- Class ----    

    function getQtyOfSharesInClass(
        uint classOfShare
    ) external view returns (uint) {
        return _repo.getQtyOfSharesInClass(classOfShare);
    }

    function getSeqListOfClass(
        uint classOfShare
    ) external view returns (uint[] memory) {
        return _repo.getSeqListOfClass(classOfShare);
    }

    function getInfoOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share memory) {
        return _repo.getInfoOfClass(classOfShare);
    }

    function getSharesOfClass(
        uint classOfShare
    ) external view returns (SharesRepo.Share[] memory) {
        return _repo.getSharesOfClass(classOfShare);
    }

    // ==== PayInCapital ====

    function getLocker(
        bytes32 hashLock
    ) external view returns (LockersRepo.Locker memory) {
        return _lockers.getLocker(hashLock);
    }

    function getLocksList() external view returns (bytes32[] memory) {
        return _lockers.getSnList();
    }
}
