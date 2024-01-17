// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenNFTsV2 {
    function transferOwnership(address newOwner) external;

    function initialize(string memory name, string memory symbol) external;

    function mintNFT(address minter, string memory jsonURI) external returns (uint256 tokenID_);

    function owner() external view returns (address owner_);
}
