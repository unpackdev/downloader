// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0xFc8f72Ac252d5409ba427629F0F1bab113a7492F
interface ISeedStorage {
    function getRandomness(bytes32 key) external view returns (uint256);
}
