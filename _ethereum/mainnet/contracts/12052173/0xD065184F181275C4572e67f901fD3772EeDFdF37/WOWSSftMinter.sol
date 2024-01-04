/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IRewardHandler.sol";
import "./IWOWSERC1155.sol";
import "./IERC1155BurnMintable.sol";

contract WOWSSftMinter is Ownable {
  using SafeERC20 for IERC20;

  // PricePerlevel, customLevel start at 0xFF
  mapping(uint16 => uint256) public _pricePerLevel;

  // The ERC1155 contract we are minting from
  IWOWSERC1155 private immutable _sftContract;

  // WOWS token contract
  IERC20 private immutable _wowsToken;

  // Reward handler which distributes WOWS
  IRewardHandler private _rewardHandler;

  // The fee is distributed to 4 channels:
  // 0.15 team
  uint32 private constant FEE_TO_TEAM = 15 * 1e4;
  // 0.15 marketing
  uint32 private constant FEE_TO_MARKETING = 15 * 1e4;
  // 0.4 booster
  uint32 private constant FEE_TO_BOOSTER = 4 * 1e5;
  // 0.3 back to reward pool
  uint32 private constant FEE_TO_REWARDPOOL = 3 * 1e5;
  // 1.0 of the rewards go to distribution
  uint32 private constant ALL = 1 * 1e6;

  event Mint(address indexed recipient, uint256 tokenId, uint256 price);

  //////////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Contruct WOWSSftMinter
   *
   * @param owner Owner of this contract
   * @param wowsToken The WOWS ERC-20 token contract
   * @param rewardHandler Handler which distributes
   * @param sftContract Cryptofolio SFT source
   */
  constructor(
    address owner,
    IERC20 wowsToken,
    IRewardHandler rewardHandler,
    IWOWSERC1155 sftContract
  ) {
    // Initialize {Ownable}
    transferOwnership(owner);

    // Initialize {WOWSSftMinter}
    _sftContract = sftContract;
    _wowsToken = wowsToken;
    _rewardHandler = rewardHandler;
  }

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set prices for the given levels
   */
  function setPrices(uint16[] memory levels, uint256[] memory prices)
    external
    onlyOwner
  {
    require(levels.length == prices.length, 'Length mismatch');
    for (uint256 i = 0; i < levels.length; ++i)
      _pricePerLevel[levels[i]] = prices[i];
  }

  /**
   * @dev Set new rewardhandler
   *
   * RewardHandler is from concept upgradeable / see investment::Controller.sol.
   */
  function setRewardHandler(IRewardHandler newRewardHandler)
    external
    onlyOwner
  {
    _rewardHandler = newRewardHandler;
  }

  /**
   * @dev Mint one of our stock card SFT's
   *
   * Approval of WOWS token required before the call.
   */
  function mintWowsSFT(
    address recipient,
    uint8 level,
    uint8 cardId
  ) external {
    uint256 price = _pricePerLevel[level];
    require(price > 0, 'No price available');

    // get the next free mintable token for level / cardId
    (bool success, uint256 tokenId) =
      _sftContract.getNextMintableTokenId(level, cardId);
    require(success, 'Unsufficient cards');

    _mint(recipient, tokenId, price);
  }

  /**
   * @dev Mint a custom token
   *
   * Approval of WOWS token required before the call.
   */
  function mintCustomSFT(
    address recipient,
    uint8 level,
    string memory uri
  ) external {
    uint256 price = _pricePerLevel[0x100 + level];
    require(price > 0, 'No price available');

    // Get the next free mintable token for level / cardId
    uint256 tokenId = _sftContract.getNextMintableCustomToken();

    // Set card level and uri
    _sftContract.setCustomCardLevel(tokenId, level);
    _sftContract.setURI(tokenId, uri);

    _mint(recipient, tokenId, price);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Query prices for given levels
   */
  function getPrices(uint16[] memory levels)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory result = new uint256[](levels.length);
    for (uint256 i = 0; i < levels.length; ++i)
      result[i] = _pricePerLevel[levels[i]];
    return result;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  function _mint(
    address recipient,
    uint256 tokenId,
    uint256 price
  ) internal {
    // Transfer WOWS from user to rewardhandler
    _wowsToken.safeTransferFrom(msg.sender, address(_rewardHandler), price);

    // Mint the token
    IERC1155BurnMintable(address(_sftContract)).mint(recipient, tokenId, 1, '');

    // Distribute the rewards
    _rewardHandler.distribute(
      recipient,
      price,
      ALL,
      FEE_TO_TEAM,
      FEE_TO_MARKETING,
      FEE_TO_BOOSTER,
      FEE_TO_REWARDPOOL
    );

    emit Mint(recipient, tokenId, price);
  }
}
