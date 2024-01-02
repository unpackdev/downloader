// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IInitializer {
    function initialize(uint32 threshold_, address lootBox, uint32 chainId) external;
}
