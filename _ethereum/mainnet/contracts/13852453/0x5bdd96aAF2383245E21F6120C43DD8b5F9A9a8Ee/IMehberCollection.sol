// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

interface IMehberCollection {

  /// @notice Mint a specified amount of a single token to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amount The number of tokens to mint
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  /// @notice Mint specified amounts of multiple tokens in one transaction to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenIds An array of IDs for tokens to mint
  /// @param amounts As array of amounts of tokens to mint, corresponding to the tokenIds
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /// @notice Mint specified amounts of a single token to multiple addresses
  /// @param recipients An array of addresses to received the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amounts As array of the number of tokens to mint to each address
  function mintToMany(
    address[] calldata recipients,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  function totalSupply(uint256 tokenId) external view returns (uint256);
}
