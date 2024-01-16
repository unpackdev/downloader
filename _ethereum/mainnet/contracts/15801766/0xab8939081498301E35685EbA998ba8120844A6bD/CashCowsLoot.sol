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

import "./Ownable.sol";
import "./AccessControl.sol";

import "./Pausable.sol";

import "./ERC1155.sol";

// ============ Contract ============

/**
 * @dev ERC721; This is the item store. You can get item using 
 * ETH or any erc20 tokeb. Loot is soulbound to the NFT, and cannot be 
 * transferred, traded or burned.
 */
contract CashCowsLoot is 
  ERC1155, 
  Ownable, 
  AccessControl,
  Pausable
{
  // ============ Errors ============

  error InvalidCall();

  // ============ Constants ============

  bytes32 private constant _BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 private constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  bytes32 private constant _APPROVED_ROLE = keccak256("APPROVED_ROLE");
  
  // ============ Storage ============

  //mapping of item id to max supply
  mapping(uint256 => uint256) private _itemMax;
  //mapping of item id to current supply
  mapping(uint256 => uint256) private _itemSupply;

  // ============ Deploy ============

  /**
   * @dev Sets the role admin
   */
  constructor(string memory _uri, address admin) ERC1155(_uri) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(_PAUSER_ROLE, admin);
  }

  // ============ Read Methods ============

  /**
   * @dev Override isApprovedForAll to whitelist marketplaces 
   * to enable gas-less listings.
   */
  function isApprovedForAll(
    address owner, 
    address operator
  ) public view override returns(bool) {
    return hasRole(_APPROVED_ROLE, operator) 
      || super.isApprovedForAll(owner, operator);
  }

  /**
   * @dev Returns the max supply of `itemId`
   */
  function maxSupply(uint256 itemId) external view returns(uint256) {
    return _itemMax[itemId];
  }

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure returns(string memory) {
    return "Cash Cows Loot";
  }

  /**
   * @dev Returns true if this contract implements the interface 
   * defined by `interfaceId`.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC1155) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure returns(string memory) {
    return "LOOT";
  }

  /**
   * @dev Returns the overall amount of tokens generated for `itemId`
   */
  function totalSupply(uint256 itemId) external view returns(uint256) {
    return _itemSupply[itemId];
  }

  // ============ Burn Methods ============

  /**
   * @dev Allows owner, burner or approved to burn
   */
  function burn(
    address account,
    uint256 itemId,
    uint256 value
  ) public virtual {
    address operator = _msgSender();
    //revert if caller is not account
    if(account != operator
      //and caller is not a burner
      && !hasRole(_BURNER_ROLE, operator)
      //and caller is not approved
      && !isApprovedForAll(account, operator)
    ) revert InvalidCall();

    _burn(account, itemId, value);
  }

  /**
   * @dev Allows owner, burner or approved to burn
   */
  function burn(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    address operator = _msgSender();
    //revert if caller is not account
    if(account != operator
      //and caller is not a burner
      && !hasRole(_BURNER_ROLE, operator)
      //and caller is not approved
      && !isApprovedForAll(account, operator)
    ) revert InvalidCall();

    _burnBatch(account, ids, values);
  }

  // ============ Admin Methods ============
  
  /**
   * @dev Allows minter role to mint (this is good for integrations)
   */
  function mint(
    address to, 
    uint256 itemId, 
    uint256 amount,
    bytes memory data
  ) external onlyRole(_MINTER_ROLE) {
    //revert if cant mint
    if (!_canMint(itemId, amount)) revert InvalidCall();
    //we can go ahead and mint
    _mint(to, itemId, amount, data);
    _itemSupply[itemId] += amount;
  }

  /**
   * @dev Allows minter role to mint (this is good for integrations)
   */
  function mint(
    address to, 
    uint256[] memory itemIds, 
    uint256[] memory amounts,
    bytes memory data
  ) external onlyRole(_MINTER_ROLE) {
    for (uint256 i; i < itemIds.length; i++) {
      //revert if cant mint
      if (!_canMint(itemIds[i], amounts[i])) revert InvalidCall();
      _itemSupply[itemIds[i]] += amounts[i];
    }
    //we can go ahead and mint
    _mintBatch(to, itemIds, amounts, data);
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(_PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Updates item max supply
   */
  function setMaxSupply(
    uint256 itemId,
    uint256 itemMax
  ) public onlyRole(_CURATOR_ROLE) {
    _itemMax[itemId] = itemMax;
  }

  /**
   * @dev Updates item max supply
   */
  function setMaxSupply(
    uint256[] memory itemIds,
    uint256[] memory itemMaxs
  ) external onlyRole(_CURATOR_ROLE) {
    if (itemIds.length != itemMaxs.length) revert InvalidCall();
    for (uint256 i; i < itemIds.length; i++) {
      setMaxSupply(itemIds[i], itemMaxs[i]);
    }
  }

  /**
   * @dev Sets the default URI
   */
  function setURI(string memory uri_) external onlyRole(_CURATOR_ROLE) {
    _setURI(uri_);
  }
  
  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(_PAUSER_ROLE) {
    _unpause();
  }

  // ============ Internal Methods ============

  /**
   * @dev Returns true if the amount exceeds the max limit
   */
  function _canMint(
    uint256 itemId, 
    uint256 amount
  ) private view returns(bool) {
    return _itemMax[itemId] == 0 
      || (_itemSupply[itemId] + amount) <= _itemMax[itemId];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory itemIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    //revert if paused
    if (paused()) revert InvalidCall();
    super._beforeTokenTransfer(operator, from, to, itemIds, amounts, data);
  }
}