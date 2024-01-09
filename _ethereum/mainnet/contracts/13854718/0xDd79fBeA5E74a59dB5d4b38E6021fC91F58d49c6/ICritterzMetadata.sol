//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICritterzMetadata {
  function getMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view returns (string memory);

  function getPlaceholderMetadata(
    uint256 tokenId,
    bool staked,
    string[] calldata additionalAttributes
  ) external view returns (string memory);

  function seed() external view returns (uint256);
}
