// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRenderer {
    function tokenURI(uint256 tokenId, address owner) external view returns (string memory);

    function svg(uint256 tokenId) external view returns (string memory);
}
