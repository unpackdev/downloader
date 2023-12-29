// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Level pool interface
interface ILevelPool {
    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to, bytes calldata extradata) external;
}

// @title Level library
// @notice Functions to swap tokens on Level protocol
library Level {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        ILevelPool(swapData.addr).swap(from, swapData.to, 0, address(this), new bytes(0));
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}
