//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemTypeV2.sol";

interface ISlothEquipmentV2 {
  function getTargetItemContractAddress(IItemTypeV2.ItemMintType _itemMintType) external view returns (address);
}