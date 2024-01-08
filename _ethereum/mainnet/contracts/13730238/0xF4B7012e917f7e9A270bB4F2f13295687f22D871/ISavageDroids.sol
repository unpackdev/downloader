// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISavageDroids {
  function mintToken(
    address recipient,
    uint256 tokenId,
    uint256 factionId
  ) external;

  function burnToken(uint256 tokenId) external;

  function getFaction(uint256 tokenId) external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);
}
