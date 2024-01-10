// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IReserve {
  function stakeMany(address account, uint16[] calldata tokenIds) external;
  function randomPoacherOwner(uint256 seed) external view returns (address);
  function numDepositedPoachersOf(address account) external view returns (uint256);
  function depositsOf(address account) external view returns (uint256[] memory);
}
