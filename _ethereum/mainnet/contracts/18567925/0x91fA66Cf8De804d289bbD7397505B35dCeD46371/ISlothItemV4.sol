//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721AQueryableUpgradeable.sol";
import "./IItemTypeV2.sol";

interface ISlothItemV4 is IERC721AQueryableUpgradeable {
  function getItemType(uint256 tokenId) external view returns (IItemTypeV2.ItemType);
  function getItemMintCount(address sender) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function clothesMint(address sender, uint256 quantity) external;
  function itemMint(address sender, uint256 quantity) external;
}