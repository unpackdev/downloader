// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title PancakeSwap pool interface
interface IPancakeStablePool {
    // @dev Same as Curve but uses uint256 instead of int128
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}

// @title PancakeSwap library
// @notice Functions to swap tokens on PancakeSwap like protocols
library PancakeSwapStable {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        (int128 i, int128 j) = abi.decode(swapData.data, (int128, int128));
        uint256 balanceBefore = IERC20(swapData.to).balanceOf(address(this));
        //slither-disable-next-line unused-return //it's safe to ignore
        IERC20(from).approve(swapData.addr, amountIn);
        IPancakeStablePool(swapData.addr).exchange(uint256(uint128(i)), uint256(uint128(j)), amountIn, 0);
        amountOut = IERC20(swapData.to).balanceOf(address(this)) - balanceBefore;
    }
}
