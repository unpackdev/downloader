// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IHandler {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
    function imageURI(uint256 tokenId, uint256 seed) external view returns (string memory);
    function htmlURI(uint256 tokenId, uint256 seed) external view returns (string memory);
    function rawSvg(uint256 tokenId, uint256 seed) external view returns (string memory);
}
