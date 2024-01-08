/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import "./ISFTEvaluator.sol";
import "./ICFolioItemHandler.sol";

import "./IWOWSCryptofolio.sol";
import "./IWOWSERC1155.sol";
import "./AddressBook.sol";
import "./IAddressRegistry.sol";
import "./TokenIds.sol";

contract SFTEvaluator is ISFTEvaluator {
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Attention: Proxy implementation: Only add new state at the end

  // Admin
  address public immutable admin;

  // The SFT contract we need for level
  IWOWSERC1155 private immutable _sftHolder;

  // The cfolioitem bridge contract
  address private immutable _cfiBridge;

  // Current reward weight of a baseCard
  mapping(uint256 => uint256) private _rewardRates;

  // cfolioType of cfolioItem
  mapping(uint256 => uint256) private _cfolioItemTypes;

  // sftMinter
  address public sftMinter;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event RewardRate(uint256 indexed tokenId, uint32 rate);

  event UpdatedCFolioType(uint256 indexed tokenId, uint256 cfolioItemType);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(IAddressRegistry addressRegistry) {
    // The SFT holder
    _sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );

    // Admin
    admin = addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);

    // CFolioItemBridge
    _cfiBridge = addressRegistry.getRegistryEntry(
      AddressBook.CFOLIOITEM_BRIDGE_PROXY
    );

    sftMinter = addressRegistry.getRegistryEntry(AddressBook.SFT_MINTER);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ISFTEvaluator}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ISFTEvaluator-rewardRate}.
   */
  function rewardRate(uint256 tokenId) external view override returns (uint32) {
    // Validate parameters
    require(tokenId.isBaseCard(), 'Invalid tokenId');

    uint256 sftTokenId = tokenId.toSftTokenId();

    // Load state
    return
      _rewardRates[sftTokenId] == 0
        ? _baseRate(sftTokenId)
        : uint32(_rewardRates[sftTokenId]);
  }

  /**
   * @dev See {ISFTEvaluator-getCFolioItemType}.
   */
  function getCFolioItemType(uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    // Validate parameters
    require(tokenId.isCFolioCard(), 'Invalid tokenId');

    // Load state
    return _cfolioItemTypes[tokenId.toSftTokenId()];
  }

  /**
   * @dev See {ISFTEvaluator-setRewardRate}.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged)
    external
    override
  {
    // Validate parameters
    require(tokenId.isBaseCard(), 'Invalid tokenId');

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

      IWOWSCryptofolio cFolio = IWOWSCryptofolio(
        _sftHolder.tokenIdToAddress(sftTokenId)
      );
      require(address(cFolio) != address(0), 'SFTE: invalid tokenId');

      // Run through all cfolioItems of cfiBridge
      (uint256[] memory cFolioItems, uint256 length) = cFolio.getCryptofolio(
        _cfiBridge
      );
      if (length > 0) {
        // Bound loop to 100 c-folio items to fit in sensible gas limits
        require(length <= 100, 'SFTE: Too many items');

        address[] memory calledHandlers = new address[](length);
        uint256 numCalledHandlers = 0;

        for (uint256 i = 0; i < length; ++i) {
          // Secondary c-folio items have one tradefloor which is the handler
          address handler = IWOWSCryptofolio(
            _sftHolder.tokenIdToAddress(cFolioItems[i].toSftTokenId())
          )._tradefloors(0);
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

  /**
   * @dev Set SFT minter, admin only.
   *
   * @param newMinter The new SFTMinter implementation
   */
  function setMinter(address newMinter) external {
    // Access control
    require(msg.sender == admin, 'SFTE: Forbidden');

    // Set state
    sftMinter = newMinter;
  }

  /**
   * @dev See {ISFTEvaluator-setCFolioType}.
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType)
    external
    override
  {
    require(tokenId.isCFolioCard(), 'Invalid tokenId');
    require(msg.sender == sftMinter, 'SFTE: Minter only');

    _cfolioItemTypes[tokenId] = cfolioItemType;

    // Dispatch event
    emit UpdatedCFolioType(tokenId, cfolioItemType);
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
