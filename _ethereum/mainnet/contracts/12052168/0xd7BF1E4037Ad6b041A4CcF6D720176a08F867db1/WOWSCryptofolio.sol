/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import "./IERC1155BurnMintable.sol";
import "./IWOWSCryptofolio.sol";
import "./IWOWSERC1155.sol";

contract WOWSCryptofolio is IWOWSCryptofolio {
  // Our NFT token parent
  IWOWSERC1155 private _deployer;
  // The owner of the NFT token parent
  address private _owner;
  // Mapping of cryptofolio items owned by this
  mapping(address => uint256[]) private _cryptofolios;
  // List of all known tradefloors
  address[] public _tradefloors;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Triggered if sft receives new tokens from operator
   */
  event CryptoFolioAdded(
    address indexed sft,
    address indexed operator,
    uint256[] tokenIds,
    uint256[] amounts
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-initialize}.
   */
  function initialize() external override {
    require(address(_deployer) == address(0), 'CF: Already initialized');
    _deployer = IWOWSERC1155(msg.sender);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSCryptofolio}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-getCryptofolio}.
   */
  function getCryptofolio(address tradefloor)
    external
    view
    override
    returns (uint256[] memory tokenIds, uint256 idsLength)
  {
    uint256[] storage opIds = _cryptofolios[tradefloor];
    uint256[] memory result = new uint256[](opIds.length);
    uint256 newLength = 0;

    if (opIds.length > 0) {
      address[] memory accounts = new address[](opIds.length);
      for (uint256 i = 0; i < opIds.length; ++i) accounts[i] = address(this);
      uint256[] memory balances =
        IERC1155(tradefloor).balanceOfBatch(accounts, opIds);

      for (uint256 i = 0; i < opIds.length; ++i)
        if (balances[i] > 0) result[newLength++] = opIds[i];
    }
    return (result, newLength);
  }

  /**
   * @dev See {IWOWSCryptofolio-setOwner}.
   */
  function setOwner(address newOwner) external override {
    require(msg.sender == address(_deployer), 'CF: Only deployer');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      if (_owner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(_owner, false);
      if (newOwner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(newOwner, true);
    }
    _owner = newOwner;
  }

  /**
   * @dev See {IWOWSCryptofolio-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool allow) external override {
    require(msg.sender == _owner, 'CF: Only owner');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      IERC1155(_tradefloors[i]).setApprovalForAll(operator, allow);
    }
  }

  /**
   * @dev See {IWOWSCryptofolio-burn}.
   */
  function burn() external override {
    require(msg.sender == address(_deployer), 'CF: Only deployer');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      IERC1155BurnMintable tradefloor = IERC1155BurnMintable(_tradefloors[i]);
      uint256[] storage opIds = _cryptofolios[address(tradefloor)];
      if (opIds.length > 0) {
        address[] memory accounts = new address[](opIds.length);
        for (uint256 j = 0; j < opIds.length; ++j) accounts[j] = address(this);
        uint256[] memory balances = tradefloor.balanceOfBatch(accounts, opIds);
        tradefloor.burnBatch(address(this), opIds, balances);
      }
      delete _cryptofolios[address(tradefloor)];
    }
    delete _tradefloors;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Hooks
  //////////////////////////////////////////////////////////////////////////////

  function onERC1155Received(
    address,
    address,
    uint256 tokenId,
    uint256 amount,
    bytes memory
  ) external returns (bytes4) {
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(tokenIds, amounts);
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external returns (bytes4) {
    _onTokensReceived(tokenIds, amounts);
    return this.onERC1155BatchReceived.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Update our collection of tradeable cryptofolio items
   *
   * This function is only allowed to be called from one of our pseudo
   * TokenReceiver contracts.
   */
  function _onTokensReceived(
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) internal {
    address tradefloor = msg.sender;
    require(_deployer.isTradeFloor(tradefloor), 'CF: Only tradefloor');
    require(tokenIds.length == amounts.length, 'CF: Input lengths differ');

    uint256[] storage currentIds = _cryptofolios[tradefloor];
    if (currentIds.length == 0) {
      IERC1155(tradefloor).setApprovalForAll(_owner, true);
      _tradefloors.push(tradefloor);
    }

    for (uint256 iIds = 0; iIds < tokenIds.length; ++iIds) {
      if (amounts[iIds] > 0) {
        uint256 tokenId = tokenIds[iIds];
        // Search tokenId
        uint256 i = 0;
        for (; i < currentIds.length && currentIds[i] != tokenId; ++i) i;
        // If token was not found, insert it
        if (i == currentIds.length) currentIds.push(tokenId);
      }
    }
    emit CryptoFolioAdded(address(this), tradefloor, tokenIds, amounts);
  }
}
