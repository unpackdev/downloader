//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721AQueryableUpgradeable.sol";
import "./IEquipmentV2.sol";
import "./IItemTypeV2.sol";

interface ISlothV3 is IERC721AQueryableUpgradeable {
  function mint(address sender, uint8 quantity) external;
  function numberMinted(address sender) external view returns (uint256);
  function setItem(uint256 _tokenId, IEquipmentV2.EquipmentTargetItem memory _targetItem, IItemTypeV2.ItemType _targetItemType, address sender) external returns (address);
  function receiveItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external;
  function sendItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external;
}