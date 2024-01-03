// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

    // 1-min = 4 blocks
    // 1-hour = 240 blocks
    // 1-day = 5760 blocks
    // 1-month = 172800 blocks
    // 6-months = 1036800 blocks

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}