// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISoakverseOG {
  function transferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 ogId) external returns (address);
  function balanceOf(address owner) external view returns (uint256 balance);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}