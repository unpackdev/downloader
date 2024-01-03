pragma solidity ^0.6.0;

interface IMinimalUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IMinimalUniswapV2Pair {
    function sync() external;
}