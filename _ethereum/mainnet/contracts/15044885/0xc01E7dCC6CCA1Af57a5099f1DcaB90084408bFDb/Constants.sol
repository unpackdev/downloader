// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

library Constants {
    /// @dev Magic constant used for multiplications/divisions
    uint256 internal constant BASE_MULTIPLIER = 1e18;
    /// @dev ETH/USD price feed decimals value
    uint256 internal constant ETH_USD_DECIMALS = 1e8;
    /// @dev USDC token decimals value
    uint256 internal constant USDC_DECIMALS = 1e6;
    /// @dev Minimum underlying lock duration, set for extra security
    uint256 internal constant MINIMUM_LOCK_DURATION = 30 days;
    /// @dev Base value used for calculating prices after discount
    uint256 internal constant DISCOUNT_BASE = 10_000;
}
