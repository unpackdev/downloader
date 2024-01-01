// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "./SigPage.sol";

import "./IInvestmentAgreement.sol";

contract InvestmentAgreement is IInvestmentAgreement, SigPage {
    using DealsRepo for DealsRepo.Repo;
    using SigsRepo for SigsRepo.Page;

    DealsRepo.Repo private _repo;

    //#################
    //##  Write I/O  ##
    //#################

    function addDeal(
        bytes32 sn,
        uint buyer,
        uint groupOfBuyer,
        uint paid,
        uint par
    ) external attorneyOrKeeper {
        uint seqOfDeal = _repo.addDeal(sn, buyer, groupOfBuyer, paid, par);
        emit AddDeal(seqOfDeal);
    }

    function regDeal(DealsRepo.Deal memory deal) 
        public attorneyOrKeeper returns(uint16 seqOfDeal) 
    {
        seqOfDeal = _repo.regDeal(deal);

        if (!isFinalized()) {
            if (deal.head.seller != 0) _sigPages[0].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[0].addBlank(true, seqOfDeal, deal.body.buyer);
        } else {
            if (deal.head.seller != 0) _sigPages[1].addBlank(false, seqOfDeal, deal.head.seller);
            _sigPages[1].addBlank(true, seqOfDeal, deal.body.buyer);
        } 
    }

    function delDeal(uint256 seq) external onlyAttorney {

        DealsRepo.Deal memory deal = _repo.deals[seq];

        if (_repo.delDeal(seq)) {
            if (deal.head.seller != 0) {
                _sigPages[0].removeBlank(deal.head.seqOfDeal, deal.head.seller);
            }
            _sigPages[0].removeBlank(deal.head.seqOfDeal, deal.body.buyer);
        }
    }

    function lockDealSubject(uint256 seq) external onlyKeeper returns (bool flag) {
        flag = _repo.lockDealSubject(seq);
    }

    function releaseDealSubject(uint256 seq)
        external onlyDK returns (bool flag)
    {
        flag = _repo.releaseDealSubject(seq);
    }

    function clearDealCP(
        uint256 seq,
        bytes32 hashLock,
        uint closingDeadline
    ) external onlyDK {
        _repo.clearDealCP(seq, hashLock, closingDeadline);
        emit ClearDealCP(seq, hashLock, closingDeadline);
    }

    function closeDeal(uint256 seq, string memory hashKey)
        external
        onlyDK
        returns (bool flag)
    {        
        flag = _repo.closeDeal(seq, hashKey);
        emit CloseDeal(seq, hashKey);
    }

    function directCloseDeal(uint256 seq)
        external
        onlyDK
        returns (bool flag)
    {        
        flag = _repo.directCloseDeal(seq);
        emit CloseDeal(seq, '');
    }

    function terminateDeal(uint256 seqOfDeal) 
        external onlyKeeper returns(bool flag)
    {
        flag = _repo.terminateDeal(seqOfDeal);
        emit TerminateDeal(seqOfDeal);
    }

    function takeGift(uint256 seq)
        external onlyKeeper returns (bool flag)
    {
        flag = _repo.takeGift(seq);
        emit CloseDeal(seq, "0");
    }

    function finalizeIA() external {
        _repo.calTypeOfIA();
        lockContents();
    }

    // ==== Swap ====

    function createSwap (
        uint seqOfMotion,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external onlyKeeper returns(SwapsRepo.Swap memory swap) {
        

        swap = _repo.createSwap(seqOfMotion, seqOfDeal, paidOfTarget, 
            seqOfPledge, caller, _gk.getROS(), _gk.getGMM());

        emit CreateSwap(seqOfDeal, SwapsRepo.codifySwap(swap));
    }

    function payOffSwap(
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint centPrice
    ) external onlyKeeper returns(SwapsRepo.Swap memory swap){
        swap = _repo.payOffSwap(seqOfMotion, seqOfDeal, 
            seqOfSwap, msgValue, centPrice, _gk.getGMM());

        emit PayOffSwap(seqOfDeal, seqOfSwap, msgValue);
    }

    function terminateSwap(
        uint seqOfMotion,
        uint seqOfDeal,
        uint seqOfSwap
    ) external onlyKeeper returns (SwapsRepo.Swap memory swap){
        swap = _repo.terminateSwap(seqOfMotion, seqOfDeal, 
            seqOfSwap, _gk.getGMM());
        emit TerminateSwap(seqOfDeal, seqOfSwap);        
    }

    function payOffApprovedDeal(
        uint seqOfDeal,
        uint msgValue,
        // uint centPrice,
        uint caller
    ) external returns (bool flag){
        flag = _repo.payOffApprovedDeal(seqOfDeal, caller);
        emit PayOffApprovedDeal(seqOfDeal, msgValue);
    }

    function requestPriceDiff(
        uint seqOfDeal,
        uint seqOfShare
    ) external onlyKeeper {
        _repo.requestPriceDiff(seqOfDeal, seqOfShare);
    }

    //  #################################
    //  ##       查询接口               ##
    //  ################################

    function getTypeOfIA() external view returns (uint8) {
        return _repo.getTypeOfIA();
    }

    // function counterOfDeal() public view returns (uint16) {
    //     return _repo.counterOfDeal();
    // }

    // function counterOfClosedDeal() public view returns (uint16) {
    //     return _repo.counterOfClosedDeal();
    // }

    // function isDeal(uint256 seqOfDeal) public view returns (bool) {
    //     return _repo.isDeal(seqOfDeal);
    // }
    
    function getDeal(uint256 seqOfDeal) external view returns (DealsRepo.Deal memory)
    {
        return _repo.getDeal(seqOfDeal);
    }

    function getSeqList() external view returns (uint[] memory) {
        return _repo.getSeqList();
    }

    // ==== Swap ====

    // function counterOfSwaps(uint seqOfDeal)
    //     external view returns (uint16)
    // {
    //     return _repo.counterOfSwaps(seqOfDeal);
    // }

    // function sumPaidOfTarget(uint seqOfDeal)
    //     external view returns (uint64)
    // {
    //     return _repo.sumPaidOfTarget(seqOfDeal);
    // }

    function getSwap(uint seqOfDeal, uint256 seqOfSwap)
        external view returns (SwapsRepo.Swap memory)
    {
        return _repo.getSwap(seqOfDeal, seqOfSwap);
    }

    function getAllSwaps(uint seqOfDeal)
        external view returns (SwapsRepo.Swap[] memory )
    {
        return _repo.getAllSwaps(seqOfDeal);
    }

    function allSwapsClosed(uint seqOfDeal)
        external view returns (bool)
    {
        return _repo.allSwapsClosed(seqOfDeal);
    } 

    // ==== Value ====

    function checkValueOfSwap(uint seqOfDeal, uint seqOfSwap)
        external view returns(uint)
    {
        return _repo.checkValueOfSwap(seqOfDeal, seqOfSwap, _gk.getCentPrice());
    }

    function checkValueOfDeal(uint seqOfDeal)
        external view returns (uint)
    {
        return _repo.checkValueOfDeal(seqOfDeal, _gk.getCentPrice());
    }
}
