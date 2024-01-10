// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IBlitmap {
    function tokenDataOf(uint256 tokenId) external view returns (bytes memory);

    function tokenCreatorOf(uint256 tokenId) external view returns (address);

    function tokenNameOf(uint256 tokenId) external view returns (string memory);
}
