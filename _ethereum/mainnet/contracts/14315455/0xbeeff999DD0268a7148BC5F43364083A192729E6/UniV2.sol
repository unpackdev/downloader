// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IUniswapV2Router02.sol";
import "./TransferHelper.sol";

contract UniV2 {
    IUniswapV2Router02 private uniswapRouter;

    constructor(address routerAddress) {
        uniswapRouter = IUniswapV2Router02(routerAddress);
    }

    function convertV2(uint amountIn, address tokenIn, address tokenOut) public returns (uint[] memory amounts) {
        uint deadline = block.timestamp + 15;
        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), amountIn);
        return uniswapRouter.swapExactTokensForTokens(amountIn, 0, getPath(tokenIn, tokenOut), address(this), deadline);
    }

    function getPath(address p1, address p2) public pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = p1;
        path[1] = p2;
        
        return path;
    }
}