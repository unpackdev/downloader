// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}