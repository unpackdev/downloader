// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IHex {
    struct TokenData {
        bytes32 hash;
        address from;
    }

    function getTokenDataLength(uint256 tokenId) external view returns (uint256);

    function getTokenDataHash(uint256 tokenId, uint256 index) external view returns (bytes32);

    function getTokenDataFrom(uint256 tokenId, uint256 index) external view returns (address);
}
