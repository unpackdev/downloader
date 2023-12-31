// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Uniswap V3 Router contract
interface IUniswapRouterV3 {
    /// @notice Parameters for single-token exact input swaps
    struct ExactInputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @notice Parameters for multi-hop exact input swaps
    struct ExactInputParams {
        bytes path; // The path of tokens to swap
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path; // The path of tokens to swap (reversed)
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}
