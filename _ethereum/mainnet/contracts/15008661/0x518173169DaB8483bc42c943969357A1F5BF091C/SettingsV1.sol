// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

function settingToPath(bytes32 setting) pure returns (bytes32[] memory) {
  bytes32[] memory path = new bytes32[](1);
  path[0] = setting;
  return path;
}

function hashPath(bytes32[] memory path) pure returns (bytes32) {
  return keccak256(abi.encode(path));
}

struct Setting {
  // Setting path identifier, the key. Can also encode array values.
  // Eg: [b32str("hardFork")]
  bytes32[] path;

  // Pacemaker block time where the change activates in seconds.
  // Code activates on the first block.timestamp > releaseTime.
  uint64 releaseTime;

  // Optional bbi-encoded bytes value. Can contain any structure.
  // Value encoding should be supported by the runtime at that future block height.
  // Eg: codebase url hints
  bytes value;
}