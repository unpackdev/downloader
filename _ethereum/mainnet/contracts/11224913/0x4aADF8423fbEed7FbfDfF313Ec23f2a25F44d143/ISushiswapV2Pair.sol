// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface ISushiswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address account) external view returns (uint);
}