// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INFT {
    function mintWithTokenURI(address to, string calldata tokenURI) external returns (uint256);
    function transferFrom(address owner, address to, uint256 tokenId) external;
    function mint(address to_, uint256 countNFTs_) external returns (uint256, uint256);
}