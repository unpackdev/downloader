// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./SharesRepo.sol";

interface ILOOKeeper {

    //##################
    //##   Modifier   ##
    //##################

    //###############
    //##   Write   ##
    //###############

    function regInvestor(
        uint userNo,
        uint groupRep,
        bytes32 idHash
        // uint seqOfLR
    ) external;

    function approveInvestor(
        uint userNo,
        uint caller,
        uint seqOfLR
    ) external;

    function revokeInvestor(
        uint userNo,
        uint caller,
        uint seqOfLR
    ) external;

    function placeInitialOffer(
        uint caller,
        uint classOfShare,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR
    ) external;

    function withdrawInitialOffer(
        uint caller,
        uint classOfShare,
        uint seqOfOrder,
        uint seqOfLR
    ) external;

    function placeSellOrder(
        uint caller,
        uint seqOfClass,
        uint execHours,
        uint paid,
        uint price,
        uint seqOfLR,
        bool sortFromHead
    ) external;

    function withdrawSellOrder(
        uint caller,
        uint classOfShare,
        uint seqOfOrder
    ) external;

    function placeBuyOrder(
        uint caller,
        uint classOfShare,
        uint paid,
        uint price,
        uint msgValue
    ) external;

}
