// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./OrdersRepo.sol";
import "./GoldChain.sol";

interface IListOfOrders {

    //################
    //##   Events   ##
    //################

    event RegInvestor(uint indexed investor, uint indexed groupRep, bytes32 indexed idHash);

    event ApproveInvestor(uint indexed investor, uint indexed verifier);

    event RevokeInvestor(uint indexed investor, uint indexed verifier);

    event PlaceSellOrder(bytes32 indexed sn);

    event WithdrawSellOrder(bytes32 indexed sn);

    event PlaceBuyOrder(uint caller, uint indexed classOfShare, uint indexed paid, uint indexed price);

    event Deal(bytes32 indexed deal);

    event OfferExpired(bytes32 indexed offer);

    event GetBalance(bytes32 indexed balance);

    //##################
    //##  Write I/O  ##
    //##################

    function regInvestor(
        uint acct,
        uint groupRep,
        bytes32 idHash
    ) external;

    function approveInvestor(
        uint userNo,
        uint verifier
    ) external;

    function revokeInvestor(
        uint userNo,
        uint verifier
    ) external;

    function placeSellOrder(
        uint classOfShare,
        uint seqOfShare,
        uint votingWeight,
        uint paid,
        uint price,
        uint execHours,
        bool sortFromHead
    ) external;

    function withdrawSellOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external returns(GoldChain.Node memory order);

    function placeBuyOrder(
        uint offeror,
        uint classOfShare,
        uint paid,
        uint price
    ) external returns (
        OrdersRepo.Deal[] memory deals,
        GoldChain.Node[] memory expired
    );

    //################
    //##  Read I/O  ##
    //################

    // ==== Investor ====

    function isInvestor(
        uint userNo
    ) external view returns(bool);

    function getInvestor(
        uint userNo
    ) external view returns(OrdersRepo.Investor memory);

    function getQtyOfInvestors() 
        external view returns(uint);

    function investorList() 
        external view returns(uint[] memory);

    function investorInfoList() 
        external view returns(OrdersRepo.Investor[] memory);

    // ==== Deals ====

    function counterOfOffers(
        uint classOfShare  
    ) external view returns(uint32);

    function headOfList(
        uint classOfShare
    ) external view returns (uint32);

    function tailOfList(
        uint classOfShare
    ) external view returns (uint32);

    function lengthOfList(
        uint classOfShare
    ) external view returns (uint);

    function getSeqList(
        uint classOfShare
    ) external view returns (uint[] memory);

    function getChain(
        uint classOfShare
    ) external view returns (GoldChain.NodeWrap[] memory);

    // ==== Order ====

    function isOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external view returns (bool);
    
    function getOrder(
        uint classOfShare,
        uint seqOfOrder
    ) external view returns (GoldChain.Node memory );

    // ==== Class ====

    function isClass(uint classOfShare) external view returns(bool);

    function getClassesList() external view returns(uint[] memory);


}
