// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface ILoot {
  function getWeapon(uint256 tokenId) external view returns (string memory);
  function getChest(uint256 tokenId) external view returns (string memory);
  function getHead(uint256 tokenId) external view returns (string memory);
  function getWaist(uint256 tokenId) external view returns (string memory);
  function getFoot(uint256 tokenId) external view returns (string memory);
  function getHand(uint256 tokenId) external view returns (string memory);
  function getNeck(uint256 tokenId) external view returns (string memory);
  function getRing(uint256 tokenId) external view returns (string memory);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function getApproved(uint256 tokenId) external view returns (address operator);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  
}