// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ERC165Checker.sol";
import "./LootmartId.sol";

/// @title AdventurerRegistry
/// @author Gary Thung
/// @notice AdventurerRegistry is a registry defining permissions for the Adventurer
contract AdventurerRegistry is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;
  using ERC165Checker for address;

  EnumerableSet.AddressSet allowed721Contracts;
  EnumerableSet.AddressSet allowed1155Contracts;

  mapping(string => bool) public itemTypes;
  string[] public itemTypesArray;

  constructor() {
    itemTypes["weapon"] = true;
    itemTypes["chest"] = true;
    itemTypes["head"] = true;
    itemTypes["waist"] = true;
    itemTypes["foot"] = true;
    itemTypes["hand"] = true;
    itemTypes["neck"] = true;
    itemTypes["ring"] = true;

    itemTypesArray = ["weapon", "chest", "head", "waist", "foot", "hand", "neck", "ring"];
  }

  function addItemType(string memory _itemType) external onlyOwner {
    require(!itemTypes[_itemType], "ItemType already added");
    itemTypes[_itemType] = true;
    itemTypesArray.push(_itemType);
  }

  function removeItemType(string memory _itemType) external onlyOwner {
    require(itemTypes[_itemType], "ItemType not found");
    delete itemTypes[_itemType];
    uint index;

    for (uint i = 0; i < itemTypesArray.length; i++) {
      if (keccak256(bytes(itemTypesArray[i])) == keccak256(bytes(_itemType))) {
        index = i;
        break;
      }
    }

    itemTypesArray[index] = itemTypesArray[itemTypesArray.length - 1];
    itemTypesArray.pop();
  }

  function add721Contract(address _contract) external onlyOwner {
    require(_contract.supportsInterface(LootmartId.INTERFACE_ID), "Must implement Lootmart interface");
    allowed721Contracts.add(_contract);
  }

  function add1155Contract(address _contract) external onlyOwner {
    require(_contract.supportsInterface(LootmartId.INTERFACE_ID), "Must implement Lootmart interface");
    allowed1155Contracts.add(_contract);
  }

  function remove721Contract(address _contract) external onlyOwner {
    allowed721Contracts.remove(_contract);
  }

  function remove1155Contract(address _contract) external onlyOwner {
    allowed1155Contracts.remove(_contract);
  }

  function allItemTypes() external view returns (string[] memory) {
    return itemTypesArray;
  }

  function isValidItemType(string memory _itemType) external view returns (bool) {
    return itemTypes[_itemType];
  }

  function isValidContract(address _contract) external view returns (bool) {
    return isValid721Contract(_contract) || isValid1155Contract(_contract);
  }

  function isValid721Contract(address _contract) public view returns (bool) {
    return allowed721Contracts.contains(_contract);
  }

  function isValid1155Contract(address _contract) public view returns (bool) {
    return allowed1155Contracts.contains(_contract);
  }
}
