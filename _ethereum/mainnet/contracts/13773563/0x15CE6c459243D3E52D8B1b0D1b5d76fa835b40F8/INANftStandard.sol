// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

interface INANftStandard {

    // ---
    // Events
    // ---

    event Mint(uint256 indexed tokenId, string metadata, address indexed owner);
}
