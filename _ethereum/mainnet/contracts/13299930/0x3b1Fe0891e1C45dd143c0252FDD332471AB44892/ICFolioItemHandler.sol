/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import "./ICFolioItemCallback.sol";

/**
 * @dev Interface to C-folio item contracts
 */
interface ICFolioItemHandler is ICFolioItemCallback {
  /**
   * @dev Called when a SFT tokens grade needs re-evaluation
   *
   * @param tokenId The ERC-1155 token ID. Rate is in 1E6 convention: 1E6 = 100%
   * @param newRate The new value rate
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external;

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param from must be msg.sender for calls not from sftMinter
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    address from,
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Removes investments from a cFolioItem SFT
   *
   * Withdrawn token are transfered back to msg.sender.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Update investment values from sidechain
   *
   * Must be called from a registered root tunnel
   *
   * @param tokenId cFolioItem tokenId
   * @param amounts Investment amounts, implementation specific
   */
  function update(uint256 tokenId, uint256[] calldata amounts) external;

  /**
   * @dev Get the rewards collected by an SFT base card
   *
   * Calls only allowed from sftMinter.
   *
   * @param owner The owner of the NFT token
   * @param recipient Recipient of the rewards (- fees)
   * @param tokenId SFT base card tokenId, must be unlocked
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external;

  /**
   * @dev Get amounts (handler specific) for a cfolioItem
   *
   * @param cfolioItem address of CFolioItem contract
   */
  function getAmounts(address cfolioItem)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Get information obout the rewardFarm
   *
   * @param tokenIds List of basecard tokenIds
   * @return bytes of uint256[]: total, rewardDur, rewardRateForDur, [share, earned]
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory);
}
