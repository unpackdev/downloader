// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "./Imports.sol";

/**
 * @notice For contracts that hold tokens and track the value locked
 */
interface ILiquidityPoolV2 {
    /**
     * @notice The token held by the pool
     * @return The token address
     */
    function underlyer() external view returns (IDetailedERC20);

    /**
     * @notice Get the total USD value locked in the pool
     * @return The total USD value
     */
    function getPoolTotalValue() external view returns (uint256);

    /**
     * @notice Get the total USD value of an amount of tokens
     * @param underlyerAmount The amount of tokens
     * @return The total USD value
     */
    function getValueFromUnderlyerAmount(uint256 underlyerAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get the USD price of the token held by the pool
     * @return The price
     */
    function getUnderlyerPrice() external view returns (uint256);
}
