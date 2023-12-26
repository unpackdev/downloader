//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IEquipmentV2.sol";

interface ISlothBodyV2 {
  function exists(uint256 tokenId) external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function getEquipments(uint256 tokenId) external view returns (IEquipmentV2.Equipment[6] memory);
}