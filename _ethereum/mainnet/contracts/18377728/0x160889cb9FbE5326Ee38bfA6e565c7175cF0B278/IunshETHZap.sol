// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IunshETHZap {
    function mint_unsheth_with_eth(uint256 amountOutMin, uint256 pathId) external payable;
}
