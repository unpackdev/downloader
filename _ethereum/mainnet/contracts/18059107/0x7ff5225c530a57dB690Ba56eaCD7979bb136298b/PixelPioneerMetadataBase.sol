// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import "./OwnableDeferralResolution.sol";
import "./IChainNativeMetadataProducer.sol";
import "./SimpleChainNativeArtConsumer.sol";
import "./CollectionMetadataManager.sol";

/**
 * @title PixelPioneerMetadataBase
 * @author @NiftyMike | @NFTCulture
 * @dev Basic On-Chain Metadata Implementation.
 */
abstract contract PixelPioneerMetadataBase is
    CollectionMetadataManager,
    SimpleChainNativeArtConsumer,
    IChainNativeMetadataProducer,
    OwnableDeferralResolution
{
    function getTokenTypeForToken(uint256 tokenId) external pure override returns (uint256) {
        return tokenId + 1; // Token types are 1-index based.
    }

    function getJsonAsString(uint256 tokenId, uint256 tokenType) external view override returns (string memory) {
        return _getMetadataJson(tokenId, tokenType);
    }

    function getJsonAsEncodedString(uint256 tokenId, uint256 tokenType) external view override returns (string memory) {
        return _convertJsonToEncodedString(_getMetadataJson(tokenId, tokenType));
    }

    function _getImageFieldValue(uint256 tokenType) internal view override returns (string memory) {
        return _getProducer().getArtAsString(tokenType);
    }

    function _getAnimationFieldValue(uint256 tokenType) internal view override returns (string memory) {
        return _getProducer().getAnimationAsString(tokenType);
    }
}
