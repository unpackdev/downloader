// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

uint8 constant DOUG_TYPES = 100;

interface IDougToken {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function dougType(uint256 tokenId) external view returns (uint8 dougType);

    function dougRank(uint256 tokenId) external view returns (uint8);
}
