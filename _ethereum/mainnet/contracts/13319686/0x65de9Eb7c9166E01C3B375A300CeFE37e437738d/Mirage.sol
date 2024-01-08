// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract ProcessedArtMirage {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function tokenHash(uint256 tokenId) public view virtual returns (bytes32);
    function tokensOfOwner(address _owner) public view virtual returns (uint256[] memory);
}