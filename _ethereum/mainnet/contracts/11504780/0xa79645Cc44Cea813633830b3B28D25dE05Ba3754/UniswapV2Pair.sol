// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface UniswapV2Pair{

function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
function price0CumulativeLast() external view returns (uint);
function price1CumulativeLast() external view returns (uint);

}