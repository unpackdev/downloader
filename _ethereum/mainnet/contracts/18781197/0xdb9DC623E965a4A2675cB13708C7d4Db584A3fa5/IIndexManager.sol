// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IIndexManager {
  struct IIndexAndStatus {
    address index;
    bool verified;
  }

  event AddIndex(address indexed index, bool verified);

  event RemoveIndex(address indexed index);

  event SetVerified(address indexed index, bool verified);

  function allIndexes() external view returns (IIndexAndStatus[] memory);

  function addIndex(address index, bool verified) external;

  function removeIndex(uint256 idx) external;

  function verifyIndex(uint256 idx, bool verified) external;
}
