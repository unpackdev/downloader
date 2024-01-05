// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./DARTVesting.sol";

contract TreasuryVesting is DARTVesting {
    uint256 public constant TOTAL_AMOUNT = 19600000 * (10**18);
    uint256 public constant RELEASE_PERIODS = 270;
    uint256 public constant LOCK_PERIODS = 0;
    uint256 public constant UNLOCK_TGE_PERCENT = 7;

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
