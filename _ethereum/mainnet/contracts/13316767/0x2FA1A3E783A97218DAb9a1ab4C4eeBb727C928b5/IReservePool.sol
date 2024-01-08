// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "./ILiquidityPoolV2.sol";

/**
 * @notice For pools that keep a separate reserve of tokens
 */
interface IReservePool is ILiquidityPoolV2 {
    /**
     * @notice Log when the percent held in reserve is changed
     * @param reservePercentage The new percent held in reserve
     */
    event ReservePercentageChanged(uint256 reservePercentage);

    /**
     * @notice Set a new percent of tokens to hold in reserve
     * @param reservePercentage_ The new percent
     */
    function setReservePercentage(uint256 reservePercentage_) external;

    /**
     * @notice Transfer an amount of tokens to the LP Account
     * @dev This should only be callable by the `MetaPoolToken`
     * @param amount The amount of tokens
     */
    function transferToLpAccount(uint256 amount) external;

    /**
     * @notice Get the amount of tokens missing from the reserve
     * @dev A negative value indicates extra tokens not needed for the reserve
     * @return The amount of missing tokens
     */
    function getReserveTopUpValue() external view returns (int256);

    /**
     * @notice Get the current percentage of tokens held in reserve
     * @return The percent
     */
    function reservePercentage() external view returns (uint256);
}
