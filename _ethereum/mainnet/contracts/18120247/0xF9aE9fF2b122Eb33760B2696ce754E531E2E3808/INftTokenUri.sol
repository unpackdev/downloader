// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftTokenUri {
  function generateTokenUri(uint256 tokenId, bool membershipActivated, uint8 tier) external pure returns (string memory);
}