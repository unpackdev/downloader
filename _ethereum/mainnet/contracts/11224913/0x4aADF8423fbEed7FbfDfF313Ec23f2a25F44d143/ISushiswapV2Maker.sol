// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface ISushiswapV2Maker {
    function convert(address token0, address token1) external;
}