// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";
import "./ERC998TopDown.sol";
import "./ILootmart.sol";

interface IRegistry {
  function isValid721Contract(address _contract) external view returns (bool);
  function isValid1155Contract(address _contract) external view returns (bool);
  function isValidContract(address _contract) external view returns (bool);
  function isValidItemType(string memory _itemType) external view returns (bool);
}

/// @title Adventurer
/// @author Gary Thung
/// @notice Adventurer is a composable NFT designed to equip other ERC721 and ERC1155 tokens
contract Adventurer is ERC721Enumerable, ERC998TopDown, Ownable {
  using ERC165Checker for address;

  struct Item {
    address itemAddress;
    uint256 id;
  }

  event Equipped(uint256 indexed tokenId, address indexed itemAddress, uint256 indexed itemId, string itemType);
  event Unequipped(uint256 indexed tokenId, address indexed itemAddress, uint256 indexed itemId, string itemType);

  mapping(uint256 => mapping(string => Item)) public equipped;

  bytes4 internal constant ERC_721_INTERFACE = 0x80ac58cd;
  bytes4 internal constant ERC_1155_INTERFACE = 0xd9b67a26;

  IRegistry internal registry;

  constructor(address _registry) ERC998TopDown("Adventurer", "ADVT") {
    registry = IRegistry(_registry);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Ensure caller affecting an adventurer is authorized.
   */
  modifier onlyAuthorized(uint256 _tokenId) {
    require(_isApprovedOrOwner(msg.sender, _tokenId), "Adventurer: Caller is not owner nor approved");
    _;
  }

  // MINTING //

  function mint() external {
    _safeMint(_msgSender(), totalSupply());
  }

  function mintToAccount(address _account) external {
    _safeMint(_account, totalSupply());
  }

  // EQUIPPING/UNEQUIPPING //

  /**
   * @dev Execute a series of equips followed by a series of unequips.
   *
   * NOTE: Clients should reduce the changes down to the simplest set.
   * For example, imagine an Adventurer with a head equipped and the goal is to equip a new head item.
   * Calling bulkChanges with both a new head to equip and a head unequip will result in the Adventurer
   * ultimately having no head equipped. The simplest change would be to do only an equip.
   */
  function bulkChanges(
    uint256 _tokenId,
    address[] memory _equipItemAddresses,
    uint256[] memory _equipItemIds,
    string[] memory _unequipItemTypes
  ) external onlyAuthorized(_tokenId) {
    // Execute equips
    for (uint256 i = 0; i < _equipItemAddresses.length; i++) {
      _equip(_tokenId, _equipItemAddresses[i], _equipItemIds[i]);
    }

    // Execute unequips
    for (uint256 i = 0; i < _unequipItemTypes.length; i++) {
      _unequip(_tokenId, _unequipItemTypes[i]);
    }
  }

  /**
   * @dev Equip an item.
   */
  function equip(
    uint256 _tokenId,
    address _itemAddress,
    uint256 _itemId
  ) external onlyAuthorized(_tokenId) {
    _equip(_tokenId, _itemAddress, _itemId);
  }

  /**
   * @dev Equip a list of items.
   */
  function equipBulk(
    uint256 _tokenId,
    address[] memory _itemAddresses,
    uint256[] memory _itemIds
  ) external onlyAuthorized(_tokenId) {
    for (uint256 i = 0; i < _itemAddresses.length; i++) {
      _equip(_tokenId, _itemAddresses[i], _itemIds[i]);
    }
  }

  /**
   * @dev Unequip an item.
   */
  function unequip(
    uint256 _tokenId,
    string memory _itemType
  ) external onlyAuthorized(_tokenId) {
    _unequip(_tokenId, _itemType);
  }

  /**
   * @dev Unequip a list of items.
   */
  function unequipBulk(
    uint256 _tokenId,
    string[] memory _itemTypes
  ) external onlyAuthorized(_tokenId) {
    for (uint256 i = 0; i < _itemTypes.length; i++) {
      _unequip(_tokenId, _itemTypes[i]);
    }
  }

  // LOGIC //

  /**
   * @dev Execute inbound transfer from a component contract to this contract.
   */
  function _transferItemIn(
    uint256 _tokenId,
    address _operator,
    address _itemAddress,
    uint256 _itemId
  ) internal {
    if (_itemAddress.supportsInterface(ERC_721_INTERFACE)) {
      IERC721(_itemAddress).safeTransferFrom(_operator, address(this), _itemId, toBytes(_tokenId));
    } else if (_itemAddress.supportsInterface(ERC_1155_INTERFACE)) {
      IERC1155(_itemAddress).safeTransferFrom(_operator, address(this), _itemId, 1, toBytes(_tokenId));
    } else {
      require(false, "Adventurer: Item does not support ERC-721 nor ERC-1155 standards");
    }
  }

  /**
   * @dev Execute outbound transfer of a child token.
   */
  function _transferItemOut(
    uint256 _tokenId,
    address _owner,
    address _itemAddress,
    uint256 _itemId
  ) internal {
    if (child721Balance(_tokenId, _itemAddress, _itemId) == 1) {
      safeTransferChild721From(_tokenId, _owner, _itemAddress, _itemId, "");
    } else if (child1155Balance(_tokenId, _itemAddress, _itemId) >= 1) {
      safeTransferChild1155From(_tokenId, _owner, _itemAddress, _itemId, 1, "");
    }
  }

  /**
   * @dev Execute the logic required to equip a single item. This involves:
   *
   * 1. Checking that the component contract is registered
   * 2. Check that the item type is valid
   * 3. Mark the new item as equipped
   * 4. Transfer the new item to this contract
   * 5. Transfer the old item back to the owner
   */
  function _equip(
    uint256 _tokenId,
    address _itemAddress,
    uint256 _itemId
  ) internal {
    require(registry.isValidContract(_itemAddress), "Adventurer: Item contract must be in the registry");

    string memory itemType = ILootmart(_itemAddress).itemTypeFor(_itemId);
    require(registry.isValidItemType(itemType), "Adventurer: Invalid item type");

    // Get current item
    Item memory item = equipped[_tokenId][itemType];
    address currentItemAddress = item.itemAddress;
    uint256 currentItemId = item.id;

    // Equip the new item
    equipped[_tokenId][itemType] = Item({ itemAddress: _itemAddress, id: _itemId });

    // Pull in the item
    _transferItemIn(_tokenId, _msgSender(), _itemAddress, _itemId);

    // Send back old item
    if (currentItemAddress != address(0)) {
      _transferItemOut(_tokenId, ownerOf(_tokenId), currentItemAddress, currentItemId);
    }

    emit Equipped(_tokenId, _itemAddress, _itemId, itemType);
  }

  /**
   * @dev Execute the logic required to equip a single item. This involves:
   *
   * 1. Mark the item as unequipped
   * 2. Transfer the item back to the owner
   */
  function _unequip(
    uint256 _tokenId,
    string memory _itemType
  ) internal {
    // Get current item
    Item memory item = equipped[_tokenId][_itemType];
    address currentItemAddress = item.itemAddress;
    uint256 currentItemId = item.id;

    // Mark item unequipped
    delete equipped[_tokenId][_itemType];

    // Send back old item
    _transferItemOut(_tokenId, ownerOf(_tokenId), currentItemAddress, currentItemId);

    emit Unequipped(_tokenId, currentItemAddress, currentItemId, _itemType);
  }

  // CALLBACKS //

  /**
   * @dev Only allow this contract to execute inbound transfers. Executes super's receiver to update underlying bookkeeping.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes memory data
  ) public override returns (bytes4) {
    require(operator == address(this), "Adventurer: Only the Adventurer contract can pull items in");
    return super.onERC721Received(operator, from, id, data);
  }

  /**
   * @dev Only allow this contract to execute inbound transfers. Executes super's receiver to update underlying bookkeeping.
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override returns (bytes4) {
    require(operator == address(this), "Only the Adventurer contract can pull items in");
    return super.onERC1155Received(operator, from, id, amount, data);
  }

  /**
   * @dev Only allow this contract to execute inbound transfers. Executes super's receiver to update underlying bookkeeping.
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
  ) public override returns (bytes4) {
    require(operator == address(this), "Only the Adventurer contract can pull items in");
    return super.onERC1155BatchReceived(operator, from, ids, values, data);
  }

  function _beforeChild721Transfer(
    address operator,
    uint256 fromTokenId,
    address to,
    address childContract,
    uint256 id,
    bytes memory data
  ) internal override virtual {
    super._beforeChild721Transfer(operator, fromTokenId, to, childContract, id, data);
  }

  function _beforeChild1155Transfer(
    address operator,
    uint256 fromTokenId,
    address to,
    address childContract,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override virtual {
    super._beforeChild1155Transfer(operator, fromTokenId, to, childContract, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // HELPERS //

  /**
   * @dev Convert uint to bytes.
   */
  function toBytes(uint256 x) internal pure returns (bytes memory b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
  }
}
