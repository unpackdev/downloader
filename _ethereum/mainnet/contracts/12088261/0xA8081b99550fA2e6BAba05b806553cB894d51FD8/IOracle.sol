//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./IUniswapV2Pair.sol";

/// Fixed window oracle that recomputes the average price for the entire period once every period
interface IOracle {
    /// Updates oracle price
    /// @dev Works only once in a period, other times reverts
    function update() external;

    /// Get the price of token.
    /// @param token The address of one of two tokens (the one to get the price for)
    /// @param amountIn The amount of token to estimate
    /// @return amountOut The amount of other token equivalent
    /// @dev This will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function pair() external view returns (IUniswapV2Pair);

    function token0() external view returns (address);

    function token1() external view returns (address);
}
