//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library VaultErrors {
    error NotAllowedToUpdateTicks();
    error InvalidManagingFee();
    error InvalidPerformanceFee();
    error OnlyPoolAllowed();
    error InvalidCollateralAmount();
    error InvalidBurnAmount();
    error TicksOutOfRange();
    error InvalidTicksSpacing();
    error OnlyFactoryAllowed();
    error LiquidityAlreadyAdded();
    error OnlyVaultAllowed();
    error PriceNotWithinThreshold();
    error PoolRepegFailed();
    error DebtGreaterThanAssets();
    error OraclePriceIsOutdated(address oracle);
    error ZeroManagerAddress();
    error TokenZeroIsNotGHO();
    error SlippageExceedThreshold();
    error InsufficientBalanceForShares();
}
