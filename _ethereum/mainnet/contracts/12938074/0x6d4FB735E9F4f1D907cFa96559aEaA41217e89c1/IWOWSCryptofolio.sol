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
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Initialize the deployed contract after creation
   *
   * This is a one time call which sets _deployer to msg.sender.
   * Subsequent calls reverts.
   */
  function initialize() external;

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return tradefloor at given index
   *
   * @param index The 0-based index in the tradefloor array
   *
   * @return The address of the tradefloor and position index
   */
  function _tradefloors(uint256 index) external view returns (address);

  /**
   * @dev Return array of cryptofolio item token IDs
   *
   * The token IDs belong to the contract TradeFloor.
   *
   * @param tradefloor The TradeFloor that items belong to
   *
   * @return tokenIds The token IDs in scope of operator
   * @return idsLength The number of valid token IDs
   */
  function getCryptofolio(address tradefloor)
    external
    view
    returns (uint256[] memory tokenIds, uint256 idsLength);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the owner of the underlying NFT
   *
   * This function is called if ownership of the parent NFT has changed.
   *
   * The new owner gets allowance to transfer cryptofolio items. The new owner
   * is allowed to transfer / burn cryptofolio items. Make sure that allowance
   * is removed from previous owner.
   *
   * @param owner The new owner of the underlying NFT, or address(0) if the
   * underlying NFT is being burned
   */
  function setOwner(address owner) external;

  /**
   * @dev Allow owner (of parent NFT) to approve external operators to transfer
   * our cryptofolio items
   *
   * The NFT owner is allowed to approve operator to handle cryptofolios.
   *
   * @param operator The operator
   * @param allow True to approve for all NFTs, false to revoke approval
   */
  function setApprovalForAll(address operator, bool allow) external;

  /**
   * @dev Burn all cryptofolio items
   *
   * In case an underlying NFT is burned, we also burn the cryptofolio.
   */
  function burn() external;
}
