// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBlitmap {
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory);
    function tokenNameOf(uint256 tokenId) external view returns (string memory);
}
