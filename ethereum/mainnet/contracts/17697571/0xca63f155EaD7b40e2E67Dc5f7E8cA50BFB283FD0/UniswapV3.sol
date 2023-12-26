// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Uniswap v3 pool interface
interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// @title Uniswap v3 library
// @notice Functions to swap tokens on Uniswap v3 and compatible protocol
library UniswapV3 {
    using SafeERC20 for IERC20;

    function swap(uint256 amountIn, IWowmaxRouter.Swap memory swapData) internal returns (uint256 amountOut) {
        bool zeroForOne = abi.decode(swapData.data, (bool));
        uint160 sqrtPriceLimitX96 = zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(swapData.addr).swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            new bytes(0)
        );
        amountOut = uint(zeroForOne ? -amount1 : -amount0);
    }

    function invokeCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata /*_data*/) internal {
        if (amount0Delta > 0 && amount1Delta < 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).safeTransfer(msg.sender, uint256(amount0Delta));
        } else if (amount0Delta < 0 && amount1Delta > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).safeTransfer(msg.sender, uint256(amount1Delta));
        } else {
            revert("WOWMAX: Uniswap v3 invariant violation");
        }
    }
}
