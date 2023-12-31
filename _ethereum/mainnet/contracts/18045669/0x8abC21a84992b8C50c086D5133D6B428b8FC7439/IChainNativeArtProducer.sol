// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IChainNativeArtProducer
 * @author @NiftyMike | @NFTCulture
 * @dev Super thin interface definition for a contract that
 * produces art in a chain native way.
 */
interface IChainNativeArtProducer {
    /**
     * Given a token type, return a string that can be directly inserted into an
     * NFT metadata attribute such as image.
     *
     * @param tokenType type of the art piece
     */
    function getArtAsString(uint256 tokenType) external view returns (string memory);

    /**
     * Given a token type, return a string that can be directly inserted into an
     * NFT metadata attribute such as animation_url.
     *
     * @param tokenType type of the art piece
     */
    function getAnimationAsString(uint256 tokenType) external view returns (string memory);
}
