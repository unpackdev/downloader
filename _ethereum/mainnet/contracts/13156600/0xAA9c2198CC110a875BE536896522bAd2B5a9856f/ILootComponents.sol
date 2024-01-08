// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILootComponents {
  function weaponComponents(uint256 tokenId) external view returns (uint256[5] memory);
  // uint256[5] =>
  //     [0] = Item ID
  //     [1] = Suffix ID (0 for none)
  //     [2] = Name Prefix ID (0 for none)
  //     [3] = Name Suffix ID (0 for none)
  //     [4] = Augmentation (0 = false, 1 = true)
}
