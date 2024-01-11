// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "./DynamicBuffer.sol";
import "./Strings.sol";

import "./Common.sol";
import "./Serializer.sol";
import "./IMetadataRenderer.sol";
import "./JsonEncoder.sol";
import "./FeaturesHelper.sol";

contract ImaginaryFriendMetadataRenderer is IMetadataRenderer {
    using JSONEncoder for bytes;
    using Serializer for Features;
    using Deserializer for FeaturesSerialized;

    /// @notice Returns the token features from data or random generation.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the corresponding flag is set.
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        FeaturesSerialized[] memory allData,
        bool autogenerate
    ) external pure override returns (Features memory, bool) {
        bytes32 entropy = autogenerate
            ? FeaturesHelper.computeEntropy(allData)
            : bytes32(0);
        return _tokenFeatures(tokenId, data, entropy);
    }

    /// @notice Returns the tokenURI for a given token.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the corresponding flag is set.
    function tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        FeaturesSerialized[] memory allData,
        bool autogenerate,
        bool countSiblings
    ) external pure override returns (string memory) {
        bytes32 entropy = autogenerate
            ? FeaturesHelper.computeEntropy(allData)
            : bytes32(0);
        return
            _tokenURI(tokenId, data, baseURI, entropy, allData, countSiblings);
    }

    // -------------------------------------------------------------------------
    //
    //  Internals for testing
    //
    // -------------------------------------------------------------------------

    /// @notice Returns the token features from data or random generation.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the entropy is set.
    function _tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        bytes32 entropy
    ) internal pure returns (Features memory, bool) {
        (FeaturesSerialized features, bool isRevealed) = FeaturesHelper
            .tokenFeatures(tokenId, data, entropy);
        return (features.deserialize(), isRevealed);
    }

    /// @notice Returns the tokenURI for a given token.
    /// @dev If data is null, the corresponding features are randomly generated
    /// provided the entropy is set.
    function _tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        bytes32 entropy,
        FeaturesSerialized[] memory allData,
        bool countSiblings
    ) internal pure returns (string memory) {
        (FeaturesSerialized features, bool isRevealed) = FeaturesHelper
            .tokenFeatures(tokenId, data, entropy);

        bytes memory uri = JSONEncoder.init(tokenId);

        if (isRevealed) {
            uint256 numIdentical = countSiblings
                ? FeaturesHelper.countTokensWithFeatures(
                    features,
                    entropy,
                    allData
                )
                : 0;
            uri.addAttributes(features.deserialize(), numIdentical);
        }

        uri.addImageUrl(baseURI, tokenId);
        uri.finalize();
        return string(uri);
    }
}
