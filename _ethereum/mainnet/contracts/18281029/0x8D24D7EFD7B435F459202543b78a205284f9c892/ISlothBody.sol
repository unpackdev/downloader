//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IEquipment.sol";

interface ISlothBody {
  function exists(uint256 tokenId) external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function getEquipments(uint256 tokenId) external view returns (IEquipment.Equipment[5] memory);
}