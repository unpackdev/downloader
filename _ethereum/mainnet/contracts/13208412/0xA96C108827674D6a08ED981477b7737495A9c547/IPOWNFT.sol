// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPOWNFT{
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}