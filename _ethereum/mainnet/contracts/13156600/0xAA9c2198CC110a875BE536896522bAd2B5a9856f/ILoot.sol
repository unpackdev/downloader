// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILoot {
  function ownerOf(uint256 tokenId) external view returns (address);

  function getWeapon(uint256 tokenId) external view returns (string calldata);
}
