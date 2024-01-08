// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOpenNFTs {
  function mintNFT(address minter, string memory jsonURI) external returns (uint256);
}
