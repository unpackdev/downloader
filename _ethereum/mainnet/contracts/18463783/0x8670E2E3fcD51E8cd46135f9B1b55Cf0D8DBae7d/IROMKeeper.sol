// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2022 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

interface IROMKeeper {
    // #################
    // ##   Write IO  ##
    // #################

    // ==== BOS funcs ====

    function setMaxQtyOfMembers(uint max) external;

    function setPayInAmt(uint seqOfShare, uint amt, uint expireDate, bytes32 hashLock) external;

    function requestPaidInCapital(bytes32 hashLock, string memory hashKey) external;

    function withdrawPayInAmt(bytes32 hashLock, uint seqOfShare) external;

    function payInCapital(
        uint seqOfShare, 
        uint amt, 
        uint msgValue, 
        uint caller
    ) external;

    function decreaseCapital(
        uint256 seqOfShare,
        uint paid,
        uint par
    ) external;

    function updatePaidInDeadline(uint256 seqOfShare, uint line) external;
}
