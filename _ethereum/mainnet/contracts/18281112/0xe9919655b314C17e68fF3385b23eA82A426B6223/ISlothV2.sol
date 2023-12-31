//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721AQueryableUpgradeable.sol";
import "./IEquipment.sol";
import "./ISlothItem.sol";

interface ISloth is IERC721AQueryableUpgradeable {
  function mint(address sender, uint8 quantity) external;
  function numberMinted(address sender) external view returns (uint256);
  function setItem(uint256 _tokenId, IEquipment.EquipmentTargetItem memory _targetItem, ISlothItem.ItemType _targetItemType, address sender) external returns (address);
  function receiveItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external;
  function sendItem(address tokenOwner, address itemContractAddress, uint256 itemTokenId) external;
}