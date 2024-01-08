//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface Router {
    
    function WETH() external pure returns (address);

   
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
   
    
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}