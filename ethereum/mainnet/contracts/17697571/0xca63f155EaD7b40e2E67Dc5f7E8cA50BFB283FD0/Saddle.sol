// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Saddle pool interface
interface ISaddlePool {
    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external;
}

// @title Saddle library
// @notice Functions to swap tokens on Saddle protocol
library Saddle {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (uint8 tokenIndexFrom, uint8 tokenIndexTo) = abi.decode(swapData.data, (uint8, uint8));
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).approve(swapData.addr, amountIn);
        ISaddlePool(swapData.addr).swap(tokenIndexFrom, tokenIndexTo, amountIn, 0, type(uint256).max);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}
