/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Check if the specified address is a known tradefloor
   *
   * @param account The address to check
   *
   * @return True if the address is a known tradefloor, false otherwise
   */
  function isTradeFloor(address account) external view returns (bool);

  /**
   * @dev Get the token ID of a given address
   *
   * A cross check is required because token ID 0 is valid.
   *
   * @param tokenAddress The address to convert to a token ID
   *
   * @return The token ID on success, or uint256(-1) if `tokenAddress` does not
   * belong to a token ID
   */
  function addressToTokenId(address tokenAddress)
    external
    view
    returns (uint256);

  /**
   * @dev Get the address for a given token ID
   *
   * @param tokenId The token ID to convert
   *
   * @return The address, or address(0) in case the token ID does not belong
   * to an NFT
   */
  function tokenIdToAddress(uint256 tokenId) external view returns (address);

  /**
   * @dev Get the next mintable token ID for the specified card
   *
   * @param level The level of the card
   * @param cardId The ID of the card
   *
   * @return bool True if a free token ID was found, false otherwise
   * @return uint256 The first free token ID if one was found, or invalid otherwise
   */
  function getNextMintableTokenId(uint8 level, uint8 cardId)
    external
    view
    returns (bool, uint256);

  /**
   * @dev Return the next mintable custom token ID
   */
  function getNextMintableCustomToken() external view returns (uint256);

  /**
   * @dev Return the level and the mint timestamp of tokenId
   *
   * @param tokenId The tokenId to query
   *
   * @return mintTimestamp The timestamp token was minted
   * @return level The level token belongs to
   */
  function getTokenData(uint256 tokenId)
    external
    view
    returns (uint64 mintTimestamp, uint8 level);

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the base URI for either predefined cards or custom cards
   * which don't have it's own URI.
   *
   * The resulting uri is baseUri+[hex(tokenId)] + '.json'. where
   * tokenId will be reduces to upper 16 bit (>> 16) before building the hex string.
   *
   */
  function setBaseMetadataURI(string memory baseContractMetadata) external;

  /**
   * @dev Set the contracts metadata URI
   *
   * @param contractMetadataURI The URI which point to the contract metadata file.
   */
  function setContractMetadataURI(string memory contractMetadataURI) external;

  /**
   * @dev Set the URI for a custom card
   *
   * @param tokenId The token ID whose URI is being set.
   * @param customURI The URI which point to an unique metadata file.
   */
  function setCustomURI(uint256 tokenId, string memory customURI) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;
}
