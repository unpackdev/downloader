// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./DARTVesting.sol";

contract MarketingVesting is DARTVesting {
    uint256 public constant TOTAL_AMOUNT = 14000000 * (10**18);
    uint256 public constant RELEASE_PERIODS = 270;
    uint256 public constant LOCK_PERIODS = 0;
    uint256 public constant UNLOCK_TGE_PERCENT = 15;

    constructor(DARTToken _dARTToken)
        DARTVesting(
            _dARTToken,
            TOTAL_AMOUNT,
            RELEASE_PERIODS,
            LOCK_PERIODS,
            UNLOCK_TGE_PERCENT
        )
    {}
}
