// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-------------------------------------------------------------------------------------------
//
//   /$$$$$$                      /$$              /$$$$$$                                   
//  /$$__  $$                    | $$             /$$__  $$                                  
// | $$  \__/  /$$$$$$   /$$$$$$$| $$$$$$$       | $$  \__/  /$$$$$$  /$$  /$$  /$$  /$$$$$$$
// | $$       |____  $$ /$$_____/| $$__  $$      | $$       /$$__  $$| $$ | $$ | $$ /$$_____/
// | $$        /$$$$$$$|  $$$$$$ | $$  \ $$      | $$      | $$  \ $$| $$ | $$ | $$|  $$$$$$ 
// | $$    $$ /$$__  $$ \____  $$| $$  | $$      | $$    $$| $$  | $$| $$ | $$ | $$ \____  $$
// |  $$$$$$/|  $$$$$$$ /$$$$$$$/| $$  | $$      |  $$$$$$/|  $$$$$$/|  $$$$$/$$$$/ /$$$$$$$/
//  \______/  \_______/|_______/ |__/  |__/       \______/  \______/  \_____/\___/ |_______/
//
//-------------------------------------------------------------------------------------------
//
// Moo.

import "./AccessControl.sol";

import "./ReentrancyGuard.sol";

import "./IERC1155.sol";
import "./SafeERC20.sol";

import "./IERC20Burnable.sol";
import "./IERC1155MintableSupply.sol";

// ============ Contract ============

/**
 * @dev ERC721; This is the item store. You can get item using 
 * ETH or any erc20 tokeb. Loot is soulbound to the NFT, and cannot be 
 * transferred, traded or burned.
 */
contract CashCowsStore is AccessControl, ReentrancyGuard {
  // ============ Errors ============

  error InvalidCall();

  // ============ Constants ============

  bytes32 private constant _FUNDER_ROLE = keccak256("FUNDER_ROLE");
  bytes32 private constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");

  IERC1155MintableSupply public immutable LOOT;
  
  // ============ Storage ============

  //mapping of item id to default price, zero add = eth
  mapping(uint256 => mapping(address => uint256)) private _itemPrice;
  //mapping of burnable tokens
  mapping(address => bool) private _burnable;

  // ============ Deploy ============

  /**
   * @dev Sets the role admin
   */
  constructor(IERC1155MintableSupply loot, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    LOOT = loot;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns a summary info of the `itemId`
   */
  function infoOf(
    uint256 itemId, 
    address[] memory tokens
  ) external view returns(uint256 supply, uint256 max, uint256[] memory prices) {
    supply = LOOT.totalSupply(itemId);
    max = LOOT.maxSupply(itemId);
    prices = new uint256[](tokens.length);
    for (uint256 i; i < tokens.length; i++) {
      prices[i] = _itemPrice[itemId][tokens[i]];
    }
  }

  /**
   * @dev Returns the eth price of `itemId`
   */
  function priceOf(
    uint256 itemId
  ) external view returns(uint256) {
    return priceOf(itemId, address(0));
  }

  /**
   * @dev Returns the ERC20 `token` price of `itemId`
   */
  function priceOf(
    uint256 itemId, 
    address token
  ) public view returns(uint256) {
    return _itemPrice[itemId][token];
  }

  // ============ Mint Methods ============

  /**
   * @dev Allows anyone to mint for anyone with erc20 token
   */
  function mint(
    address token,
    address to, 
    uint256 itemId,
    uint256 amount
  ) external payable nonReentrant {
    //get the price
    uint256 price = _itemPrice[itemId][token];
    //revert there is no price
    if (price == 0) revert InvalidCall();
    //if zero add (it's eth)
    if (token == address(0)) {
      //revert if the eth sent is less than price x amount
      if (msg.value < (price * amount)) revert InvalidCall();
    //if burnable
    } else if (_burnable[token]) {
      //burn it. muhahaha
      //(the payer is the caller)
      IERC20Burnable(token).burnFrom(_msgSender(), price * amount);
    } else {
      //transfer it here
      //(the payer is the caller)
      //this will only pass if we have the allowance...
      IERC20(token).transferFrom(
        _msgSender(), 
        address(this), 
        price * amount
      );
    }

    //we can go ahead and mint
    LOOT.mint(to, itemId, amount, "");
  }

  /**
   * @dev Allows anyone to batch mint for anyone with erc20 token
   */
  function mint(
    address token,
    address to, 
    uint256[] memory itemIds,
    uint256[] memory amounts
  ) public payable nonReentrant {
    //revert if length mismatch
    if (itemIds.length != amounts.length) revert InvalidCall();
    uint256 total;
    for (uint256 i; i < itemIds.length; i++) {
      //revert if no price
      if (_itemPrice[itemIds[i]][token] == 0) revert InvalidCall();
      total += _itemPrice[itemIds[i]][token] * amounts[i];
    }

    //if zero add (it's eth)
    if (token == address(0)) {
      //revert if the eth sent is less than total
      if (msg.value < total) revert InvalidCall();
    //if burnable
    } else if (_burnable[token]) {
      //burn it. muhahaha
      //(the payer is the caller)
      IERC20Burnable(token).burnFrom(_msgSender(), total);
    } else {
      //transfer it here
      //(the payer is the caller)
      //this will only pass if we have the allowance...
      IERC20(token).transferFrom(
        _msgSender(), 
        address(this), 
        total
      );
    }

    //we can go ahead and mint
    LOOT.mint(to, itemIds, amounts, "");
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets a token address that we will be burning when used on 
   * minting. This is like MILK or DOLLA
   */
  function burnable(
    IERC20 token, 
    bool yes
  ) external onlyRole(_CURATOR_ROLE) {
    _burnable[address(token)] = yes;
  }

  /**
   * @dev Sets the retail `token` `prices` of an `itemId`
   */
  function setPrice(
    uint256 itemId, 
    address[] memory tokens,
    uint256[] memory prices
  ) public onlyRole(_CURATOR_ROLE) {
    if (tokens.length != prices.length) revert InvalidCall();
    for (uint256 i; i < tokens.length; i++) {
      _itemPrice[itemId][tokens[i]] = prices[i];
    }
  }

  /**
   * @dev Sets the retail `tokens` `prices` for these `itemIds`
   */
  function setPrice(
    uint256[] memory itemIds, 
    address[][] memory tokens,
    uint256[][] memory prices
  ) external onlyRole(_CURATOR_ROLE) {
    if (itemIds.length != tokens.length
      || tokens.length != prices.length
    ) revert InvalidCall();

    for (uint256 i; i < itemIds.length; i++) {
      setPrice(itemIds[i], tokens[i], prices[i]);
    }
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`. 
   */
  function withdraw(
    address recipient
  ) external nonReentrant onlyRole(_FUNDER_ROLE) {
    Address.sendValue(payable(recipient), address(this).balance);
  }

  /**
   * @dev Sends the `amount` token out to a `recipient`.
   */
  function withdraw(
    IERC20 erc20, 
    address recipient, 
    uint256 amount
  ) external nonReentrant onlyRole(_FUNDER_ROLE) {
    SafeERC20.safeTransfer(erc20, recipient, amount);
  }

  // ============ Internal Methods ============
}