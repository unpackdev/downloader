// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMNFT721 {
   function tokenURI(uint256 tokenId) external view returns(string memory);

   function ownerOf(uint256 tokenId) external view returns (address owner_);

   function mintNFT(string[] memory tokenURIs_, address owner_) external;

   function owner() external view returns(address);
}