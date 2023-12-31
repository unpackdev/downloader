// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IDynamicArtV1
 * @author @NFTMike | @NFTCulture
 * @dev Interface that defines the datastructure of on-chain artwork.
 */
interface IDynamicArtV1 {
    struct DynamicArtV1 {
        uint256 tokenType;
        string encodedArt;
        string backgroundColor;
        bytes encodedArtBytes;
    }
}
