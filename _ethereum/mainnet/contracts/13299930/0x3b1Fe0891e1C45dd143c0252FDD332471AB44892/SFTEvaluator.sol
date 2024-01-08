/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import "./Context.sol";

import "./IWOWSCryptofolio.sol";
import "./IWOWSERC1155.sol";
import "./AddressBook.sol";
import "./IAddressRegistry.sol";
import "./TokenIds.sol";

import "./ISFTEvaluator.sol";
import "./ICFolioItemHandler.sol";

contract SFTEvaluator is ISFTEvaluator, Context {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Attention: Proxy implementation: Only add new state at the end

  // Admin
  address private immutable _admin;

  // The SFT contract we need for level
  IWOWSERC1155 private immutable _sftHolder;

  // Current reward weight of a baseCard
  mapping(uint256 => uint256) private _rewardRates;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event Constructed(address admin, address sftHolder);

  event RewardRate(uint256 indexed tokenId, uint32 rate);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(IAddressRegistry addressRegistry) {
    // The SFT holder
    address sftHolder = addressRegistry.getRegistryEntry(
      AddressBook.SFT_HOLDER_PROXY
    );
    _sftHolder = IWOWSERC1155(sftHolder);

    // Admin
    address admin = addressRegistry.getRegistryEntry(AddressBook.ADMIN_ACCOUNT);
    _admin = admin;

    // Fire event
    emit Constructed(admin, sftHolder);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ISFTEvaluator}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ISFTEvaluator-rewardRate}.
   */
  function rewardRate(uint256 tokenId) external view override returns (uint32) {
    // Validate parameters
    require(tokenId.isBaseCard(), 'SFTE: Invalid tokenId');

    uint256 sftTokenId = tokenId.toSftTokenId();

    // Load state
    return
      _rewardRates[sftTokenId] == 0
        ? _baseRate(sftTokenId)
        : uint32(_rewardRates[sftTokenId]);
  }

  /**
   * @dev See {ISFTEvaluator-setRewardRate}.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged)
    external
    override
  {
    // Validate parameters
    require(tokenId.isBaseCard(), 'SFTE: Invalid tokenId');

    // We allow upgrades of locked and unlocked SFTs
    uint256 sftTokenId = tokenId.toSftTokenId();

    // Load state
    (
      uint32 untimed,
      uint32 timed // solhint-disable-next-line not-rely-on-time
    ) = _baseRates(sftTokenId, uint64(block.timestamp - 60 days));

    // First implementation, check timed auto upgrade only
    if (untimed != timed) {
      // Update state
      _rewardRates[sftTokenId] = timed;

      address cFolio = _sftHolder.tokenIdToAddress(sftTokenId);
      require(cFolio != address(0), 'SFTE: invalid tokenId');

      // Run through all cfolioItems
      uint256[] memory cFolioItems = _sftHolder.getTokenIds(cFolio);
      uint256 length = cFolioItems.length;
      if (length > 0) {
        // Bound loop to 100 c-folio items to fit in sensible gas limits
        require(length <= 100, 'SFTE: Too many items');

        address[] memory calledHandlers = new address[](length);
        uint256 numCalledHandlers = 0;

        for (uint256 i = 0; i < length; ++i) {
          // Secondary c-folio items have one tradefloor which is the handler
          address handler = IWOWSCryptofolio(
            _sftHolder.tokenIdToAddress(cFolioItems[i])
          ).handler();
          require(
            address(handler) != address(0),
            'SFTE: invalid cfolioItemHandler'
          );

          // Check if we have called this handler already
          uint256 j = numCalledHandlers;
          while (j > 0 && calledHandlers[j - 1] != handler) --j;
          if (j == 0) {
            ICFolioItemHandler(handler).sftUpgrade(sftTokenId, timed);
            calledHandlers[numCalledHandlers++] = handler;
          }
        }
      }

      // Fire an event
      emit RewardRate(tokenId, timed);
    } else {
      // Revert if requested
      require(!revertUnchanged, 'Rate unchanged');
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  function _baseRate(uint256 sftTokenId) private view returns (uint32) {
    (uint32 untimed, ) = _baseRates(sftTokenId, 0);
    return untimed;
  }

  function _baseRates(uint256 tokenId, uint64 upgradeTime)
    private
    view
    returns (uint32 untimed, uint32 timed)
  {
    uint32[4] memory rates = [
      uint32(25e4),
      uint32(50e4),
      uint32(75e4),
      uint32(1e6)
    ];

    // Load state
    (uint64 time, uint8 level) = _sftHolder.getTokenData(
      tokenId.toSftTokenId()
    );

    uint32 update = (level & 3) <= 1 && time <= upgradeTime ? 125e3 : 0;

    return (rates[(level & 3)], rates[(level & 3)] + update);
  }
}
