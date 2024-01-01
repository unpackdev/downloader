// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts and resulting pool state from swaps
interface ISolidlyV3PoolQuoter {
    /// @notice Returns the amounts in/out and resulting pool state for a swap without executing the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @return amount0 The delta of the pool's balance of token0 that will result from the swap (exact when negative, minimum when positive)
    /// @return amount1 The delta of the pool's balance of token1 that will result from the swap (exact when negative, minimum when positive)
    /// @return sqrtPriceX96After The value the pool's sqrtPriceX96 will have after the swap
    /// @return tickAfter The value the pool's tick will have after the swap
    /// @return liquidityAfter The value the pool's liquidity will have after the swap
    function quoteSwap(
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    )
        external
        view
        returns (int256 amount0, int256 amount1, uint160 sqrtPriceX96After, int24 tickAfter, uint128 liquidityAfter);
}
