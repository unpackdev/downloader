/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Sft holder contract
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

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

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Get the balance of an account's Tokens
   * @param owner  The address of the token holder
   * @param tokenId ID of the Token
   * @return The _owner's balance of the token type requested
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param owners The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Mints tokenIds into 'to' account
   * @dev Emits SftTokenTransfer Event
   *
   * Throws if sender has no MINTER_ROLE
   * 'data' holds the CFolioItemHandler if CFI's are minted
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external;

  /**
   * @notice Burns tokenIds owned by 'account'
   * @dev Emits SftTokenTransfer Event
   *
   * Burns all owned CFolioItems
   * Throws if CFolioItems have assets
   */
  function burnBatch(address account, uint256[] calldata tokenIds) external;

  /**
   * @notice Transfers amount of an id from the from address to the 'to' address specified
   * @dev Emits SftTokenTransfer Event
   * Throws if 'to' is the zero address
   * Throws if 'from' is not the current owner
   * If 'to' is a smart contract, ERC1155TokenReceiver interface will checked
   * @param from    Source address
   * @param to      Target address
   * @param tokenId ID of the token type
   * @param amount  Transfered amount
   * @param data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Batch version of {safeTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;

  /**
   * @dev Sets the cfolioItemType of a cfolioItem tokenId, not yet used
   * sftHolder tokenId expected (without hash)
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType_) external;

  /**
   * @dev Sets external NFT for display tokenId
   * By default NFT is rendered using our internal metadata
   *
   * Throws if not called from MINTER role
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external;

  /**
   * @dev Deletes external NFT settings
   *
   * Throws if not called from MINTER role
   */
  function deleteExternalNft(uint256 tokenId) external;
}
