// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISwapRouter.sol";
import "./IERC20.sol";

contract Swap {
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    function execute(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        address receiver,
        uint amountIn
    ) public returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: receiver,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }

}
