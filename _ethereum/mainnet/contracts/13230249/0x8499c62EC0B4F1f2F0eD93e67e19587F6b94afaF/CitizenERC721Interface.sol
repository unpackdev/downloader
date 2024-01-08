// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/**
 * @title  Interface for Citizen ERC721 Token Contract.
 */
interface CitizenERC721Interface {

  function mint(address recipient) external;
  function setDevice(uint256 tokenId, string memory publicKeyHash, string memory merkleRoot) external;
  function deviceRoot(uint256 tokenId) external returns(string memory);
  function deviceId(uint256 tokenId) external returns(string memory);

}