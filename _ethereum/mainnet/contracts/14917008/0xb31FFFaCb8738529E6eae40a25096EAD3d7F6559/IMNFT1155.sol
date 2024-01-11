// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMNFT1155 {
   function mintNFT(address owner_, string calldata tokenURI_, uint256 amount_) external;

   function owner() external view returns(address);
}