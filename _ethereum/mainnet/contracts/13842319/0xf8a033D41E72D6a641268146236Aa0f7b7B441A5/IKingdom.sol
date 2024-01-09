// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IKingdom {
  function addManyToKingdom(address account, uint16[] calldata tokenIds) external;
  function randomDemonOwner(uint256 seed) external view returns (address);
  function recycleExp(uint256 amount) external;
}