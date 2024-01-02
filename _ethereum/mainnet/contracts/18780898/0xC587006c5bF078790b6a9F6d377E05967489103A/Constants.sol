// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library Constants {
    /// @dev Used for price digits in the basis (10000 -> 1)
    uint256 internal constant PRICE_DIGIT = 10000;

    /// @dev Used for percentage digits in the basis (10000 -> 100%)
    uint256 internal constant PCT_DIGIT = 10000;

    /// @dev Used for seconds in year (60 * 60 * 24 * 365)
    uint256 internal constant SECONDS_IN_YEAR = 31536000;

    /// @dev Used for maximum order count per currency
    uint256 internal constant MAXIMUM_ORDER_COUNT = 20;
}
