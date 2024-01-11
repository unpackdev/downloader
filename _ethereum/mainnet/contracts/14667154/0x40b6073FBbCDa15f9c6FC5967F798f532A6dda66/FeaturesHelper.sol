// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "./DynamicBuffer.sol";
import "./Strings.sol";

import "./Common.sol";
import "./Serializer.sol";

/// @notice A helper library to generate and handle token features.
library FeaturesHelper {
    using Serializer for Features;
    using Deserializer for FeaturesSerialized;

    /// @notice Generates random token features.
    /// @dev This method is used to generate features for tokens that were not
    /// set in the quiz.
    /// @dev The generated features will never be `Special` or contain `body=2`.
    /// @param tokenId the token of interest.
    /// @param entropy a shared entropy used for the randomization.
    function generateRandomFeatures(uint256 tokenId, bytes32 entropy)
        internal
        pure
        returns (Features memory)
    {
        unchecked {
            Features memory features;
            uint256 rand = uint256(
                keccak256(abi.encode(entropy ^ bytes32(tokenId)))
            );

            // Special treatment for the body trait to exclude bodyId = 2
            // from random sampling.
            uint8 body = uint8((uint64(rand) % (NUM_BODIES - 1)) + 1);
            if (body >= 2) {
                body += 1;
            }

            features.body = body;
            rand >>= 64;
            features.mouth = uint8((uint64(rand) % NUM_MOUTHS) + 1);
            rand >>= 64;
            features.eyes = uint8((uint64(rand) % NUM_EYES) + 1);

            features.background = 13;
            features.special = Special.None;
            features.golden = (tokenId == 0);
            return features;
        }
    }

    /// @notice Retrieves the token features based on quiz data and entropy.
    /// @param tokenId the token of interest.
    /// @param data the token features set in the quiz.
    /// @param entropy a shared entropy used for the randomization.
    /// @return features Either the features set in the quiz or auto-generated
    /// ones if the entropy is non-zero. Null otherwise.
    /// @return isRevealed Flag denoting that the returned features are valid
    /// (either from data or auto-generated).
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        bytes32 entropy
    ) internal pure returns (FeaturesSerialized, bool) {
        if (entropy == 0 && !data.isSet()) {
            return (FeaturesSerialized.wrap(bytes32(0)), false);
        }

        if (entropy > 0 && !data.isSet()) {
            return (generateRandomFeatures(tokenId, entropy).serialize(), true);
        }

        return (data, true);
    }

    /// @notice Counts how many revealed tokens have the given set of features.
    /// @dev Token features are auto-generated if not set and non-zero entropy.
    /// @param features the features of interest.
    /// @param entropy collection-wide, shared entropy
    /// @param allData token data for which the counting is performed. Usually
    /// all tokens in the collection.
    function countTokensWithFeatures(
        FeaturesSerialized features,
        bytes32 entropy,
        FeaturesSerialized[] memory allData
    ) internal pure returns (uint256) {
        uint256 numTokens = allData.length;
        bytes32 tokenHash = features.hash();
        uint256 numIdentical = 0;

        for (uint256 idx = 0; idx < numTokens; ++idx) {
            (
                FeaturesSerialized sibling,
                bool isSiblingRevealed
            ) = tokenFeatures(idx, allData[idx], entropy);

            if (!isSiblingRevealed) continue;
            if (tokenHash == sibling.hash()) ++numIdentical;
        }

        return numIdentical;
    }

    /// @notice Computes the entropy of given quiz results.
    /// @param data The tokenData to be hashed - usually the output of
    /// `_loadAllTokens` in the main collection contract.
    function computeEntropy(FeaturesSerialized[] memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(data));
    }
}
