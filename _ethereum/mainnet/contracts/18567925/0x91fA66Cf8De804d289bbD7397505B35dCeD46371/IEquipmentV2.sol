//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IItemTypeV2.sol";

interface IEquipmentV2 {
  struct EquipmentTargetItem {
    uint256 itemTokenId;
    IItemTypeV2.ItemMintType itemMintType; 
  }
  struct Equipment {
    uint256 itemId;
    address itemAddr;
  }
  struct EquipmentTargetSpecial {
    uint256 specialType;
    bool combinationable;
  }
}