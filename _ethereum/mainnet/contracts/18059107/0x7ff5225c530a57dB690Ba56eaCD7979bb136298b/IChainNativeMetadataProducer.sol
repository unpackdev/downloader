// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IChainNativeMetadataProducer
 * @author @NiftyMike | @NFTCulture
 * @dev Super thin interface definition for a contract that
 * produces metadata in a chain native way.
 */
interface IChainNativeMetadataProducer {
    function getTokenTypeForToken(uint256 tokenId) external view returns (uint256);

    function getJsonAsString(uint256 tokenId, uint256 tokenType) external view returns (string memory);

    function getJsonAsEncodedString(uint256 tokenId, uint256 tokenType) external view returns (string memory);
}
