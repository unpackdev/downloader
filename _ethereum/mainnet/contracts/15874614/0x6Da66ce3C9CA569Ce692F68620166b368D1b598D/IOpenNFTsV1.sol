// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenNFTsV1 {
    function mintNFT(address minter, string memory jsonURI) external returns (uint256 tokenID);
}
