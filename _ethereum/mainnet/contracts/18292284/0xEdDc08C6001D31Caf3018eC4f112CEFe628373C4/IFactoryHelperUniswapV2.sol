// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFactoryHelperUniswapV2 {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}