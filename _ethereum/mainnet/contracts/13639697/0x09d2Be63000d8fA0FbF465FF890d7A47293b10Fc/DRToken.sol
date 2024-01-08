// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface DRToken {
    function mintTo(address _to, uint256 collection) external; 
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address sender, address to, uint256 id) external; 
    function balanceOf(address owner) external returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
}