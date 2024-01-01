// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IThumbnailer {
    function getThumbnailUrl(uint256 tokenId) external view returns (bytes memory);
}
