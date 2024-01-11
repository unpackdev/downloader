//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDex {

    event NativeFundsSwapped(address tokenOut, uint amountIn, uint amountOut);
    
    event ERC20FundsSwapped(uint amountIn, address tokenIn, address tokenOut, uint amountOut);

    function swapNative(address _tokenOut,
        bytes memory extraData) external payable returns (uint amountOut);
    
    function swapERC20(
        address _tokenIn,
        address _tokenOut,
        uint amountIn,
        bytes memory extraData) external returns (uint amountOut);

}