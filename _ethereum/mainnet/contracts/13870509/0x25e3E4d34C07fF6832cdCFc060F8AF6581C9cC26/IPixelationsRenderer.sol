// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPixelationsRenderer {
    function tokenURI(uint256 tokenId, bytes memory tokenData) external pure returns (string memory);
    function tokenSVG(bytes memory tokenData) external pure returns (string memory);
}
