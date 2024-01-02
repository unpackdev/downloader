//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemTypeV2.sol";
import "./IERC721AQueryableUpgradeable.sol";

interface ISpecialSlothItemV4 is IERC721AQueryableUpgradeable, IItemTypeV2 {
  function getItemType(uint256 tokenId) external view returns (IItemTypeV2.ItemType);
  function getSpecialType(uint256 tokenId) external view returns (uint256);
  function getClothType(uint256 tokenId) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function isCombinational(uint256 _specialType) external view returns (bool);
  function mintPoupelle(address sender, uint256 quantity) external;
  function mintCollaboCloth(address sender, uint256 quantity, uint256 _specialType) external;
  function mintHalloweenJiangshiSet(address sender, uint256 quantity) external;
  function mintHalloweenJacKOLanternSet(address sender, uint256 quantity) external;
  function mintHalloweenGhostSet(address sender, uint256 quantity) external;
  function mintSlothCollectionNovember(address sender, uint256 quantity, uint8 clothType) external;
  function mintSlothCollection(address sender, uint256 quantity, uint8 clothType, uint256 specialType) external;
}
