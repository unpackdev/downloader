// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IAaveLendingPool {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    /// @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    /// @param asset The address of the underlying asset to deposit
    /// @param amount The amount to be deposited
    /// @param onBehalfOf The address that will receive the aTokens
    /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    /// @param asset The address of the underlying asset to withdraw
    /// @param amount The underlying amount to be withdrawn
    /// @param to Address that will receive the underlying, same as msg.sender if the user
    /// @return The final amount withdrawn
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @dev Returns the state and configuration of the reserve
    /// @param asset The address of the underlying asset of the reserve
    /// @return The state of the reserve
    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);
}
