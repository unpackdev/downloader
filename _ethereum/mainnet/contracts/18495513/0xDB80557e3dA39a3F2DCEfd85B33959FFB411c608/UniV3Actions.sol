// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IUniswapRouterV3WithDeadline.sol";
import "./IUniswapRouterV3.sol";

/// @title Library to interact with uniswap v3
/// @dev Library for Uniswap V3 actions.
library UniV3Actions {
    /// @dev Performs a Uniswap V3 swap with a deadline.
    /// @param _router The address of the Uniswap V3 router.
    /// @param _path The path of tokens for the swap.
    /// @param _amount The input amount for the swap.
    /// @param _amountOutMinimum The minimum amount of output tokens expected from the swap.
    /// @return amountOut The amount of output tokens received from the swap.
    function swapV3WithDeadline(
        address _router,
        bytes memory _path,
        uint256 _amount,
        uint256 _amountOutMinimum
    ) internal returns (uint256 amountOut) {
        IUniswapRouterV3WithDeadline.ExactInputParams
            memory swapParams = IUniswapRouterV3WithDeadline.ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: _amountOutMinimum
            });
        return IUniswapRouterV3WithDeadline(_router).exactInput(swapParams);
    }
}
