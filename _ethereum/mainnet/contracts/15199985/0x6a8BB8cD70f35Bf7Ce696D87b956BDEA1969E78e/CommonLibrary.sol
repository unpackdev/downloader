//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./Constants.sol";

library CommonLibrary {
    function swapExactTokenBySushi(
        uint256 amountIn,
        address tokenA,
        address tokenB
    ) internal returns (uint256 amountToken) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory amounts = IUniswapV2Router02(Constants.SUSHI_ROUTER)
            .swapExactTokensForTokens(
                amountIn,
                uint256(0),
                path,
                address(this),
                block.timestamp
            );
        amountToken = amounts[amounts.length - 1];
    }

    function swapExactTokenByV2(
        uint256 amountIn,
        address tokenA,
        address tokenB
    ) public returns (uint256 amountToken) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory amounts = IUniswapV2Router02(
            Constants.UNISWAP_V2_ROUTER
        ).swapExactTokensForTokens(
                amountIn,
                uint256(0),
                path,
                address(this),
                block.timestamp
            );
        amountToken = amounts[amounts.length - 1];
    }

    function swapExactTokenByV3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bytes calldata data
    ) internal returns (uint256 amountToken) {
        (uint256 amountOutMin, , uint24 fee) = abi.decode(
            data,
            (uint256, uint8, uint24)
        );
        ISwapRouter swapRouter = ISwapRouter(Constants.UNISWAP_V3_ROUTER);
        amountToken = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            })
        );
    }
}
