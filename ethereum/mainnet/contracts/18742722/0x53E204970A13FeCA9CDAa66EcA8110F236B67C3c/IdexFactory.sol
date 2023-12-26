//SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

interface IdexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}