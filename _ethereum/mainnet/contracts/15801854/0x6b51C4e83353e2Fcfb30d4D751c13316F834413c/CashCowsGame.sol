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

import "./Context.sol";
import "./ECDSA.sol";

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

import "./IERC20Burnable.sol";
import "./IERC20Mintable.sol";

import "./console.sol";

// ============ Interface ============

interface IERC1155Mintable is IERC1155, IERC1155Receiver {
  function mint(
    address to, 
    uint256 itemId, 
    uint256 amount,
    bytes memory data
  ) external;
}

// ============ Contract ============

/**
 * @dev This links items to characters. Some items are stakable. 
 * A character can hold only one type of item at a time.
 */
contract CashCowsGame is Context, ReentrancyGuard, AccessControl {
  using Address for address;

  // ============ Errors ============

  error InvalidCall();

  // ============ Struct ============

  struct Collection {
    address collectionAddress;
    uint256 collectionTokenId;
  }

  // ============ Events ============

  //emitted when item is linked to character
  event Linked(uint256 characterId, uint256 itemId);
  //emitted when item is unlinked from character
  event Unlinked(uint256 characterId, uint256 itemId);

  // ============ Constants ============

  bytes32 private constant _FUNDER_ROLE = keccak256("FUNDER_ROLE");
  bytes32 private constant _MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant _CURATOR_ROLE = keccak256("CURATOR_ROLE");
  
  // ============ Storage ============

  //mapping of item id -> character id -> start time
  mapping(uint256 => mapping(uint256 => uint256)) private _start; 
  //mapping of item id -> character id -> erc20 token -> last time redeemed
  mapping(uint256 => mapping(uint256 => mapping(IERC20 => uint256))) private _redeemed;
  //if minting with erc20, this checks to 
  //see if we should burn the token or not
  mapping(address => bool) private _burnable;
  //mapping of item id -> whether if it can be unlinked
  mapping(uint256 => bool) _unlinkable;
  //all used items (this is so we can iterate)
  uint256[] private _registry;
  //mapping of an item and whether if it's in the registry
  mapping(uint256 => bool) private _registered;
  //balances per character id
  mapping(uint256 => uint256) private _balances;
  
  // ============ Deploy ============

  /**
   * @dev Sets the role admin
   */
  constructor(address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }
  
  // ============ Read Methods ============

  /**
   * @dev Returns of the time when `itemId` was linked with `characterId`
   */
  function linkedSince(
    uint256 characterId, 
    uint256 itemId
  ) external view returns(uint256) {
    return _start[itemId][characterId];
  }

  /**
   * @dev Calculate how many a `token` a `characterId` `itemId` earned
   * given the `rate`
   */
  function redeemable(
    IERC20 token, 
    uint256 characterId, 
    uint256 itemId,
    uint256 rate
  ) public view returns(uint256) {
    return redeemable(token, characterId, itemId, block.timestamp, rate);
  }

  /**
   * @dev Calculate how many a `token` a `characterId` `itemId` earned
   * given the `timestamp` and `rate`
   */
  function redeemable(
    IERC20 token, 
    uint256 characterId, 
    uint256 itemId,
    uint256 timestamp,
    uint256 rate
  ) public view returns(uint256) {
    uint256 start = redeemed(token, characterId, itemId);
    if (start == 0) return 0;
    //FORMULA: duration * rate
    return (timestamp - start) * rate;
  }

  /**
   * @dev Returns the last time this was redeemed were already 
   * released for `collection` `tokenId`
   */
  function redeemed(
    IERC20 token,
    uint256 characterId, 
    uint256 itemId
  ) public view returns(uint256) {
    return _start[itemId][characterId] > _redeemed[itemId][characterId][token]
      ? _start[itemId][characterId]
      : _redeemed[itemId][characterId][token];
  }

  /**
   * @dev Returns a list of items a character holds. This is an 
   * incredibly inefficient method to call from another contract
   */
  function items(
    uint256 characterId
  ) external view returns(Collection[] memory) {
    Collection[] memory characterItems = new Collection[](_balances[characterId]);
    uint256 index;
    for (uint256 i; i < _registry.length; i++) {
      if (_start[_registry[i]][characterId] > 0) {
        ( //get the item address and item token id
          address itemAddress, 
          uint256 itemTokenId
        ) = _unpackCollection(_registry[i]);
        characterItems[index++] = Collection(itemAddress, itemTokenId);
      }
    }

    return characterItems;
  }

  // ============ Handler Methods ============

  /**
   * @dev Handles the receipt of a single ERC1155 token type. This 
   * function is called at the end of a `safeTransferFrom` after the 
   * balance has been updated.
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns(bytes4) {
    return 0xf23a6e61;
  }

  /**
   * @dev Handles the receipt of a multiple ERC1155 token types. This 
   * function is called at the end of a `safeBatchTransferFrom` after 
   * the balances have been updated.
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns(bytes4) {
    return 0xbc197c81;
  }
  
  // ============ Write Methods ============

  /**
   * @dev Allows anyone to deposit an `amount` of `itemId` they 
   * own to a `characterId`. This includes even gifting.
   */
  function link(
    uint256 characterId, 
    uint256 itemId,
    bytes calldata data
  ) public {
    //link first
    _link(characterId, itemId);
    ( //get the item address and item token id
      address itemAddress, 
      uint256 itemTokenId
    ) = _unpackCollection(itemId);
    //try to transfer that item into the game
    IERC1155(itemAddress).safeTransferFrom(
      _msgSender(),
      address(this),
      itemTokenId,
      1,
      data
    );
  }

  /**
   * @dev Mints an `amount` of `itemId` for `characterId`   
   * from the `store` for `price` each, given `proof`
   */
  function mint(
    uint256 characterId, 
    uint256 itemId,
    uint256 price,
    bytes memory proof
  ) external payable {
    //revert if no price 
    if (price == 0 
      //or if the eth sent was less than the price
      || msg.value < price
      //or invalid proof
      || !hasRole(_MINTER_ROLE, ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(
            "mint", 
            characterId,
            itemId,
            price
          ))
        ),
        proof
      ))
    ) revert InvalidCall();
    
    _mint(characterId, itemId);
  }

  /**
   * @dev Mints an `amount` of `itemId` for `characterId`   
   * from the `store` for `token` `price` each, given `proof`
   */
  function mint(
    address token,
    uint256 characterId, 
    uint256 itemId,
    uint256 price,
    bytes memory proof
  ) external {
    //revert if no price 
    if (price == 0 
      //or invalid proof
      || !hasRole(_MINTER_ROLE, ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(
            "mint",
            token, 
            characterId,
            itemId,
            price
          ))
        ),
        proof
      ))
    ) revert InvalidCall();

    //if burnable
    if (_burnable[token]) {
      //burn it. muhahaha
      //(the payer is the caller)
      IERC20Burnable(token).burnFrom(_msgSender(), price);
    } else {
      //transfer it here
      //(the payer is the caller)
      //this will only pass if we have the allowance...
      IERC20(token).transferFrom(_msgSender(), address(this), price);
    }
    
    _mint(characterId, itemId);
  }

  /**
   * @dev Redeem tokens for an item. Rate is determined off chain.
   */
  function redeem(
    IERC20Mintable token, 
    uint256 characterId,
    uint256 itemId,
    uint256 rate, 
    bytes memory proof
  ) external {
    //revert if invalid proof
    if (!hasRole(_MINTER_ROLE, ECDSA.recover(
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(
          "redeem", 
          address(token),
          itemId,
          rate
        ))
      ),
      proof
    ))) revert InvalidCall();
    //get the staker
    address staker = _msgSender();
    ( //get the character address and character token id
      address characterAddress, 
      uint256 characterTokenId
    ) = _unpackCollection(characterId);
    //if not owner
    if (IERC721(characterAddress).ownerOf(characterTokenId) != staker) 
      revert InvalidCall();

    //get pending
    uint256 pending = redeemable(token, characterId, itemId, rate);
    //update time
    _redeemed[itemId][characterId][token] = block.timestamp;

    //next mint tokens
    address(token).functionCall(
      abi.encodeWithSelector(
        IERC20Mintable(token).mint.selector, 
        staker, 
        pending
      ), 
      "Low-level mint failed"
    );
  }

  /**
   * @dev Allows anyone to safely deposit an `amount` of `itemId` they 
   * own to a `characterId`. This includes even gifting.
   */
  function safeLink(
    uint256 characterId, 
    uint256 itemId, 
    bytes calldata data
  ) external {
    ( //get the character address and character id
      address characterAddress, 
      uint256 characterTokenId
    ) = _unpackCollection(itemId);

    try IERC721(characterAddress).ownerOf(characterTokenId)
    returns(address owner) {
      if (owner == address(0)) revert InvalidCall();
    } catch(bytes memory) {
      revert InvalidCall();
    }

    link(characterId, itemId, data);
  }

  /**
   * @dev Allows the owner of the `characterId` to withdraw an `amount` 
   * of `itemId` back to them.
   */
  function unlink(
    uint256 characterId, 
    uint256 itemId, 
    address to,
    bytes calldata data
  ) external {
    //revert if item is unlinkable
    if (!_unlinkable[itemId]) revert InvalidCall();
    ( //get the character address and character id
      address characterAddress, 
      uint256 characterTokenId
    ) = _unpackCollection(characterId);
    try IERC721(characterAddress).ownerOf(characterTokenId)
    returns(address owner) {
      if (owner != _msgSender()) revert InvalidCall();
    } catch(bytes memory) {
      revert InvalidCall();
    }

    _unlink(characterId, itemId, to, data);
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
   * @dev Allows admin to mint an `amount` of `itemId` for `characterId`   
   * from the `store` for `token` `price` each
   */
  function mint(
    uint256 characterId, 
    uint256 itemId
  ) external onlyRole(_MINTER_ROLE) {
    _mint(characterId, itemId);
  }

  /**
   * @dev Allows admin to `characterId` to withdraw an `amount` 
   * of `itemId` back to them.
   */
  function unlink(
    uint256 characterId, 
    uint256 itemId, 
    bytes calldata data
  ) external onlyRole(_CURATOR_ROLE) {
    ( //get the character address and character id
      address characterAddress, 
      uint256 characterTokenId
    ) = _unpackCollection(characterId);
    //can only withdraw
    _unlink(
      characterId, 
      itemId, 
      IERC721(characterAddress).ownerOf(characterTokenId), 
      data
    );
  }

  /**
   * @dev Allows/revokes the ability for items to be unlinked
   */
  function unlinkable(
    uint256 itemId, 
    bool yes
  ) external onlyRole(_CURATOR_ROLE) {
    _unlinkable[itemId] = yes;
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

  /**
   * @dev Mints an `amount` of `itemId` for `characterId`   
   * from the `store` for `token` `price` each, given `proof`
   */
  function _mint(
    uint256 characterId, 
    uint256 itemId
  ) internal {
    //first link
    _link(characterId, itemId);
    ( //get the item address and item token id
      address itemAddress, 
      uint256 itemTokenId
    ) = _unpackCollection(itemId);
    //mint to this address
    IERC1155Mintable(itemAddress).mint(address(this), itemTokenId, 1, "");
  }

  /**
   * @dev Allows anyone to deposit an `amount` of `itemId` they 
   * own to a `characterId`. This includes even gifting.
   */
  function _link(uint256 characterId, uint256 itemId) internal {
    //revert if already linked
    if (_start[itemId][characterId] > 0) revert InvalidCall();
    //add to character item balance
    _start[itemId][characterId] = block.timestamp;
    //add to balance
    _balances[characterId]++;
    //if it's not registered
    if (!_registered[itemId]) {
      //register it
      _registered[itemId] = true;
      _registry.push(itemId);
    }
    //emit deposited
    emit Linked(characterId, itemId);
  }

  /**
   * @dev Allows the owner of the `characterId` to withdraw an `amount` 
   * of `itemId` back to them.
   */
  function _unlink(
    uint256 characterId, 
    uint256 itemId, 
    address to,
    bytes calldata data
  ) internal {
    //revert if character item is not staked
    if (_start[itemId][characterId] == 0) revert InvalidCall();
    ( //get the item address and item token id
      address itemAddress, 
      uint256 itemTokenId
    ) = _unpackCollection(itemId);
    //try to transfer out to the intended recipient
    IERC1155(itemAddress).safeTransferFrom(
      address(this),
      to,
      itemTokenId,
      1,
      data
    );
    //remove start time
    delete _start[itemId][characterId];
    //less from balance
    _balances[characterId]--;
    //emit unlinked
    emit Unlinked(characterId, itemId);
  }
  
  // ============ Pack Methods ============

  // Bits Layout:
  // - [0..159]   `address of collection`
  // - [160..] `tokenId`

  //length of token in packed data
  uint256 private constant _BIT_TOKEN_MASK = (1 << 192) - 1;
  //length of collection in packed data
  uint256 private constant _BIT_COLLECTION_MASK = (1 << 160) - 1;
  //position of token in packed data
  uint256 private constant _BIT_TOKEN_POSITION = 160;

  /**
   * @dev Unpacks collection data from uint256 `packed`
   */
  function _unpackCollection(
    uint256 packed
  ) internal pure returns(address collection, uint256 tokenId) {
    return (
      _unpackCollectionAddress(packed),
      _unpackCollectionTokenId(packed)
    );
  }

  /**
   * @dev Unpacks collection address from uint256 `packed` collection data
   */
  function _unpackCollectionAddress(
    uint256 packed
  ) internal pure returns(address) {
    return address(uint160(packed & _BIT_COLLECTION_MASK));
  }

  /**
   * @dev Unpacks token id from uint256 `packed` collection data
   */
  function _unpackCollectionTokenId(
    uint256 packed
  ) internal pure returns(uint256) {
    return (packed >> _BIT_TOKEN_POSITION) & _BIT_COLLECTION_MASK;
  }
}