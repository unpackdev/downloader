// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IReserveInterestRateStrategy.sol";
import "./IPoolAddressesProvider.sol";

/**
 * @title IDefaultInterestRateStrategy
 *
 * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
 */
interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
    /**
     * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
     * @return The optimal usage ratio, expressed in ray.
     */
    function OPTIMAL_USAGE_RATIO() external view returns (uint256);

    /**
     * @notice Returns the excess usage ratio above the optimal.
     * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
     * @return The max excess usage ratio, expressed in ray.
     */
    function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

    /**
     * @notice Returns the address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the variable rate slope below optimal usage ratio
     * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
     * @return The variable rate slope, expressed in ray
     */
    function getVariableRateSlope1() external view returns (uint256);

    /**
     * @notice Returns the variable rate slope above optimal usage ratio
     * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
     * @return The variable rate slope, expressed in ray
     */
    function getVariableRateSlope2() external view returns (uint256);

    /**
     * @notice Returns the base variable borrow rate
     * @return The base variable borrow rate, expressed in ray
     */
    function getBaseVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Returns the maximum variable borrow rate
     * @return The maximum variable borrow rate, expressed in ray
     */
    function getMaxVariableBorrowRate() external view returns (uint256);
}
