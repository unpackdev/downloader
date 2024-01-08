// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapRouter {
	function WETH() external pure returns (address);

  function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}