// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILiquidityOwner {
    function payWETHToUniswapPool(address uniswapPool, uint256 extraAmount) external;
    function payDeveloperFee(uint256 developerFee) external;
    function provideLiquidity(uint112 collectedEthInCycle)
        external
        returns (uint256 issuancePrice);
}
