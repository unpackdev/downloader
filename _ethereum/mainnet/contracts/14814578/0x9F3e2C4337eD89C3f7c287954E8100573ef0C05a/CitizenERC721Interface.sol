// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/**
 * @title  Interface for Citizen ERC721 Token Contract.
 */
interface CitizenERC721Interface {

  function mint(address recipient) external;
  function mintCitizen(address recipient) external;
  function mintCitizenTitan(address recipient) external;
  function setDevice(uint256 tokenId, bytes32 publicKeyHash, bytes32 merkleRoot) external;
  function deviceRoot(uint256 tokenId) external returns(bytes32);
  function deviceId(uint256 tokenId) external returns(bytes32);

}