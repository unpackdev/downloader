// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface MNFTFactoryV3I {
    // @notice Create a clone of a contract and call an initializer function on it
    function createWithInitializer(bytes calldata callData) external returns (address);
}
