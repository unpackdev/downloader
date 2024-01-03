//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./IERC20.sol";

interface IV2Router {

    function addLiquidity(IERC20 tokenA, uint aAmount, IERC20 tokenB, uint bAmount)
        external 
        returns (address);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        view
        returns (uint amount);
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        view
        returns (uint amount);
}