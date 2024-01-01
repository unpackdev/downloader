// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./OptionsRepo.sol";
import "./SwapsRepo.sol";

interface IROOKeeper {
    // #################
    // ##  ROOKeeper  ##
    // #################

    function updateOracle(
        uint256 seqOfOpt,
        uint d1,
        uint d2,
        uint d3
    ) external;

    function execOption(uint256 seqOfOpt, uint256 caller)
        external;

    function createSwap(
        uint256 seqOfOpt,
        uint seqOfTarget,
        uint paidOfTarget,
        uint seqOfPledge,
        uint256 caller
    ) external;

    function payOffSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        uint msgValue,
        uint caller
    ) external;

    function terminateSwap(
        uint256 seqOfOpt, 
        uint256 seqOfSwap,
        uint caller
    ) external;

    // ==== Swap ====

    function requestToBuy(
        address ia,
        uint seqOfDeal,
        uint paidOfTarget,
        uint seqOfPledge,
        uint caller
    ) external;

    function payOffRejectedDeal(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        uint msgValue,
        uint caller
    ) external;

    function pickupPledgedShare(
        address ia,
        uint seqOfDeal,
        uint seqOfSwap,
        uint caller
    ) external;


}
