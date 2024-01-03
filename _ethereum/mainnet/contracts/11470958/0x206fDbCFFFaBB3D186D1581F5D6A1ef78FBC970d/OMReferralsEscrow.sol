// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IntervalEscrow.sol";

contract OMReferralsEscrow is IntervalEscrow {
    constructor(
        uint256 exitTimeout_,
        uint256 firstIntervalPerBlockReleaseAmount,
        uint256 strategyChangeTimeout_,
        address owner_,
        uint256[] memory intervals,
        IERC20 token_
    )
        public
        IntervalEscrow(
            exitTimeout_,
            firstIntervalPerBlockReleaseAmount,
            strategyChangeTimeout_,
            owner_,
            intervals,
            token_
        )
    {}
}
