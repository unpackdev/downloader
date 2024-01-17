// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenNFTsV0 {
    function addUser(address minter, string memory jsonURI) external returns (uint256 tokenID);
}
