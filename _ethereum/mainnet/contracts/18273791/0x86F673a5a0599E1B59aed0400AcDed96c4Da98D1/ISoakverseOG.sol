// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISoakverseOG {
  function transferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 ogId) external returns (address);
}