// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IUniswapTrader {
    struct Path {
        address tokenOut;
        uint256 firstPoolFee;
        address tokenInTokenOut;
        uint256 secondPoolFee;
        address tokenIn;
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param fee The Uniswap pool fee
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    function addPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint24 slippageNumerator
    ) external;

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(
        address tokenA,
        address tokenB,
        uint256 poolIndex,
        uint24 slippageNumerator
    ) external;

    /// @notice Changes which Uniswap pool to use as the default pool
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(
        address tokenA,
        address tokenB,
        uint256 primaryPoolIndex
    ) external;

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountInMaximum);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getPathFor(address tokenOut, address tokenIn)
        external
        view
        returns (Path memory);

    function setPathFor(
        address tokenOut,
        address tokenIn,
        uint256 firstPoolFee,
        address tokenInTokenOut,
        uint256 secondPoolFee
    ) external;

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1);

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB)
        external
        view
        returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(
        address tokenA,
        address tokenB,
        uint256 poolId
    ) external view returns (uint24 feeNumerator);

    function getPoolAddress(address tokenA, address tokenB)
        external
        view
        returns (address pool);
}
