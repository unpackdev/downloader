// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IProtectedIsland {
  function addManyToProtectedIslandAndPack(address account, uint16[] calldata tokenIds) external;
  function randomGoatOwner(uint256 seed) external view returns (address);
}