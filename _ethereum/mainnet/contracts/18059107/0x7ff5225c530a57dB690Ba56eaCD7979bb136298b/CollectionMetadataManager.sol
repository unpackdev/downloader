// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// OZ Libraries
import "./Strings.sol";
import "./Base64.sol";

// Local References
import "./OwnableDeferral.sol";
import "./TokenMetadataManager.sol";

/**
 * @title CollectionMetadataManager
 * @author @NiftyMike | @NFTCulture
 * @dev This contract builds on TokenMetadataManager to provide functionality that enables on-chain
 * storage of NFT metadata for an entire NFT collection.
 */
abstract contract CollectionMetadataManager is TokenMetadataManager, OwnableDeferral {
    using Strings for uint256;

    string private _description;
    string private _external_url;

    constructor(string memory __description, string memory __external_url) {
        _description = __description;
        _external_url = __external_url;
    }

    function _getImageFieldValue(uint256 tokenType) internal view virtual returns (string memory);

    function _getAnimationFieldValue(uint256 tokenType) internal view virtual returns (string memory);

    function _convertJsonToEncodedString(string memory metadata) internal pure returns (string memory) {
        return string.concat('data:application/json;base64,', Base64.encode(bytes(metadata)));
    }

    function _getMetadataJson(uint256 tokenId, uint256 tokenType) internal view returns (string memory) {
        return _constructMetadataAsJson(tokenId, tokenType);
    }

    function _constructMetadataAsJson(uint256 tokenId, uint256 tokenType) internal view returns (string memory) {
        DynamicAttributesV1 memory tokenAttributes = _getTokenAttributesDefinition(tokenType);

        // Token types are 1-index based.
        require(tokenAttributes.tokenType > 0, 'Invalid token type');

        string memory imageFieldValue = _getImageFieldValue(tokenType);
        string memory animationFieldValue = _getAnimationFieldValue(tokenType);

        return
            string.concat(
                '{"name":"',
                tokenAttributes.title,
                tokenAttributes.isSerialized ? tokenId.toString() : '',
                '","description":"',
                tokenAttributes.hasTokenDescription ? tokenAttributes.tokenDescription : _description,
                '","image":"',
                imageFieldValue,
                tokenAttributes.isAnimated ? '","animation_url":"' : '',
                tokenAttributes.isAnimated ? animationFieldValue : '',
                '","attributes":',
                _getNftAttributeArray(tokenAttributes),
                ',"external_url":"',
                _external_url,
                '"}'
            );
    }

    function _getNftAttributeArray(DynamicAttributesV1 memory tokenAttributes) internal pure returns (string memory) {
        string memory attributeArrayAsString = '[';

        uint256 tokenAttrIdx;
        for (tokenAttrIdx; tokenAttrIdx < tokenAttributes.attributeNames.length; tokenAttrIdx++) {
            attributeArrayAsString = string.concat(
                attributeArrayAsString,
                tokenAttrIdx == 0 ? '' : ',',
                '{"trait_type":"',
                tokenAttributes.attributeNames[tokenAttrIdx],
                '","value":"',
                tokenAttributes.attributeValues[tokenAttrIdx],
                '"}'
            );
        }

        return string.concat(attributeArrayAsString, ']');
    }

    function modifyCollectionMetadata(string calldata __description, string calldata __external_url) external isOwner {
        if (bytes(__description).length > 0) {
            _description = __description;
        }

        if (bytes(__external_url).length > 0) {
            _external_url = __external_url;
        }
    }
}
