// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILBAC {
  function ownerOf(uint256) external view returns (address owner);
  function balanceOf(address) external view returns (uint256);
  function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}