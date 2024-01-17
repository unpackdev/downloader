// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;


interface IToken {
    function uniswapV2Pair() external view returns (address);
    function owner() external view returns (address);
}