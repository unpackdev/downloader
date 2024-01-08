// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IArena {
  function addManyToArenaAndPack(address account, uint16[] calldata tokenIds) external;
  function randomGuardOwner(uint256 seed) external view returns (address);
}