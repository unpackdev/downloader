// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IListOfOrders.sol";
import "./AccessControl.sol";

contract ListOfOrders is IListOfOrders, AccessControl {
    using OrdersRepo for OrdersRepo.Repo;
    using OrdersRepo for OrdersRepo.Deal;
    using GoldChain for GoldChain.Chain;
    using GoldChain for GoldChain.Node;

    OrdersRepo.Repo private _repo;

    //#################
    //##  Write I/O  ##
    //#################

    // ==== Investor ====

    function regInvestor(
        uint userNo,
        uint groupRep,
        bytes32 idHash
    ) external onlyDK {
        _repo.regInvestor(userNo, groupRep, idHash);
        emit RegInvestor(userNo, groupRep, idHash);
    }

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _repo.approveInvestor(userNo, verifier);
        emit ApproveInvestor(userNo, verifier);
    }        

    function revokeInvestor(
        uint userNo,
        uint verifier
    ) external onlyDK {
        _repo.revokeInvestor(userNo, verifier);
        emit RevokeInvestor(userNo, verifier);
    }

    // ==== Order ====

    function placeSellOrder(
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead
    ) external onlyDK {
        bytes32 sn = _repo.placeSellOrder(
            classOfShare, 
            seqOfShare,
            votingWeight,
            paid, 
            price,
            execHours,
            sortFromHead 
        );

        emit PlaceSellOrder(sn);
    }

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external onlyDK returns(GoldChain.Node memory order) {

        order = _repo.withdrawSellOrder(
            classOfShare, 
            seqOfOrder
        );

        emit WithdrawSellOrder(order.codifyNode());
    }


    function placeBuyOrder(
        uint caller,
        uint classOfShare,
        uint paid,
        uint price
    ) external onlyDK returns (
        OrdersRepo.Deal[] memory deals, 
        GoldChain.Node[] memory expired
    ) {
        OrdersRepo.Deal memory balance;

        (deals, balance, expired) = 
            _repo.placeBuyOrder(
                caller,
                classOfShare,
                paid,
                price
            );

        emit PlaceBuyOrder(caller, classOfShare, paid, price);

        uint len = deals.length;
        while (len > 0) {
            emit Deal(deals[len - 1].codifyDeal());
            len--;
        }

        len = expired.length;
        while (len > 0) {
            emit OfferExpired(expired[len - 1].codifyNode());
            len--;
        }
        
        if (balance.paid > 0)
            emit GetBalance(balance.codifyDeal());

    }

    // function removeDeals() external onlyDK {
    //     _repo.removeDeals();
    // }


    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool) {
        return _repo.isInvestor(userNo);
    }

    function getInvestor(
        uint userNo
    ) external view returns(OrdersRepo.Investor memory) {
        return _repo.getInvestor(userNo);
    }

    function getQtyOfInvestors() 
        external view returns(uint) 
    {
        return _repo.getQtyOfInvestors();
    }

    function investorList() 
        external view returns(uint[] memory) 
    {
        return _repo.investorList();
    }

    function investorInfoList() 
        external view returns(OrdersRepo.Investor[] memory) 
    {
        return _repo.investorInfoList();
    }

    // ==== Chain ====

    function counterOfOffers(
        uint classOfShare
    ) external view returns (uint32) {
        return _repo.ordersOfClass[classOfShare].counter();
    }

    function headOfList(
        uint classOfShare
    ) external view returns (uint32) {
        return _repo.ordersOfClass[classOfShare].head();
    }

    function tailOfList(
        uint classOfShare
    ) external view returns (uint32) {
        return _repo.ordersOfClass[classOfShare].tail();
    }

    function lengthOfList(
        uint classOfShare
    ) external view returns (uint) {
        return _repo.ordersOfClass[classOfShare].length();
    }

    function getSeqList(
        uint classOfShare
    ) external view returns (uint[] memory) {
        return _repo.ordersOfClass[classOfShare].getSeqList();
    }

    function getChain(
        uint classOfShare
    ) external view returns (GoldChain.NodeWrap[] memory) {
        return _repo.ordersOfClass[classOfShare].getChain();
    }

    // ==== Order ====

    function isOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external view returns (bool) {
        return _repo.ordersOfClass[classOfShare].isNode(seqOfOrder);
    }
    
    function getOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external view returns (GoldChain.Node memory ) {
        return _repo.ordersOfClass[classOfShare].
            getNode(seqOfOrder);
    }

    // ==== Class ====

    function isClass(uint classOfShare) external view returns(bool) {
        return _repo.isClass(classOfShare);
    }

    function getClassesList() external view returns(uint[] memory) {
        return _repo.getClassesList();
    }

}
