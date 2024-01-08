// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface INftRandomness {

    function getNewTraits(address owner, uint16 tokenId) external view returns (uint8[] memory);
    function getFusionTraits(address owner, uint16 tokenId, uint8[] calldata first, uint8[] calldata second) external view returns (uint8[] memory);
}
