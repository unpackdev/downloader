// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
  function getChunkId() external view returns (uint256);
  function random(uint256 data) external returns (uint256);
  function randomChunk(uint256 chunkId, uint256 data) external returns (uint256);
}
