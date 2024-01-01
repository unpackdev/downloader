// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256 n
    );

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256 n) external view returns (address pair);

    function allPairsLength() external view returns (uint256 n);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
