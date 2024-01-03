//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

interface IPairFactory {

    function createPair(address a, address b) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}