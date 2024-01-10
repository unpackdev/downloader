//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapV2Router {
    function WETH() external returns (address);
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}
