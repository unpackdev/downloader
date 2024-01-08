// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router {

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForTokens(

    //amount of tokens we are sending in
        uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
        uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
        address[] calldata path,
    //this is the address we are going to send the output tokens to
        address to,
    //the last time that the trade is valid for
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}