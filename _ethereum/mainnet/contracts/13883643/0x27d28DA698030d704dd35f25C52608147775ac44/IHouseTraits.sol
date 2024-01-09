// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface IHouseTraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}