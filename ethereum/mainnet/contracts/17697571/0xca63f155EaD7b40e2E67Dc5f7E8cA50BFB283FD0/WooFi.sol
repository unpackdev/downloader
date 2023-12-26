// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title WooFi pool interface
interface IWooFiPool {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);
}

// @title WooFi library
// @notice Functions to swap tokens on WooFi protocol
library WooFi {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeTransfer(swapData.addr, amountIn);
        amountOut = IWooFiPool(swapData.addr).swap(from, swapData.to, amountIn, 0, address(this), address(0x0));
    }
}
