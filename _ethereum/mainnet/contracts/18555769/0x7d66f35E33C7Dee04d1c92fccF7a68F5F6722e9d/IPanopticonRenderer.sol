// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPanopticonRenderer {
    function getImage(uint256 tokenId, uint256 tokenHash) external view returns (string memory);
    function getHTML(uint256 tokenId, uint256 tokenHash) external view returns (string memory);
    function getMetadata(uint256 tokenId, uint256 tokenHash) external view returns (string memory);
    function tokenURI(uint256 tokenId, uint256 tokenHash) external view returns (string memory);
}
