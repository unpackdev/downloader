// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBlitmapCRConverter {
    function getBlitmapLayer(uint256 tokenId) external view returns (bytes memory);
    function tokenNameOf(uint256 tokenId) external view returns (string memory);
}
