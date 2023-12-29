// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWowmaxRouter.sol";

// @title Wombat pool interface
interface IWombatPool {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);
}

// @title Wombat library
// @notice Functions to swap tokens on Wombat protocol
library Wombat {
    using SafeERC20 for IERC20;

    function swap(
        address from,
        uint256 amountIn,
        IWowmaxRouter.Swap memory swapData
    ) internal returns (uint256 amountOut) {
        IERC20(from).safeApprove(swapData.addr, amountIn);
        (amountOut, ) = IWombatPool(swapData.addr).swap(
            from,
            swapData.to,
            amountIn,
            0,
            address(this),
            type(uint256).max
        );
    }
}
