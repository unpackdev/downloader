// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IUniswapV3Pool.sol";
import "./IUniswapV3SwapCallback.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";

abstract contract UniswapV3Executor is IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    function swapUniswapV3(
        uint256 amountSpecified,
        IUniswapV3Pool pool,
        address recipient,
        bool zeroForOne,
        uint160 sqrtPriceLimitX96
    ) external {
        pool.swap(
            recipient,
            zeroForOne,
            amountSpecified.toInt256(),
            sqrtPriceLimitX96,
            ""
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata /* data */
    ) external override {
        if (amount0Delta > 0) {
            IERC20 token0 = IERC20(IUniswapV3Pool(msg.sender).token0());
            token0.safeTransfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20 token1 = IERC20(IUniswapV3Pool(msg.sender).token1());
            token1.safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }
}
