// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOpenNFTsV2 {
  function transferOwnership(address newOwner) external;

  function initialize(string memory name_, string memory symbol_) external;

  function mintNFT(address minter, string memory jsonURI) external returns (uint256);

  function owner() external view returns (address);
}
