//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface IPairFactory {

    function createPair(address a, address b) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}