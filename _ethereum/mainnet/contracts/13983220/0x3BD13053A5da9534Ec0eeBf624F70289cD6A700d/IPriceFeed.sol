// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPriceFeed {
    function getUniswapRouter() external view returns (address);

    function wethToken() external view returns (address);

    function howManyTokensAinB(
        address tokenA,
        address tokenB,
        uint256 amount
    ) external view returns (uint256);
}
