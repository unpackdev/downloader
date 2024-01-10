//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

interface IERC721A {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
