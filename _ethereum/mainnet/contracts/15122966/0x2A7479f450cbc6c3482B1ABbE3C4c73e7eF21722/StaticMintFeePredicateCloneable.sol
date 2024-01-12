// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ICollectionCloneable.sol";
import "./ICollectionNFTMintFeePredicate.sol";
import "./ICollection.sol";
import "./IHashes.sol";

/**
 * @title  StaticMintFeePredicateCloneable
 * @author David Matheson
 * @notice This is a helper contract used to provide mint fee logic upon instantiating a new
 *         contract from CollectionNFTCloneableV1 to create a new Hashes NFT collection.
 *         This contract includes a function, getTokenMintFee, where a mint fee is provided
 *         and the function will then return the mint fee to initialize it within the associated contract.
 */
contract StaticMintFeePredicateCloneable is ICollectionCloneable, ICollectionNFTMintFeePredicate, ICollection {
    bool _initialized;
    uint256 public mintFee;

    function initialize(
        IHashes,
        address,
        address,
        bytes memory _initializationData
    ) external override {
        require(!_initialized, "StaticMintFeePredicateCloneable: already initialized.");

        (mintFee) = abi.decode(_initializationData, (uint256));

        _initialized = true;
    }

    /**
     * @notice This predicate function is used to provide the mint free of a new hashes collection by
     * returning the mint fee provided during initialization.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The hashes token Id being used to mint.
     *
     * @return The mint fee provided during initialization.
     */
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (uint256) {
        require(_initialized, "StaticMintFeePredicateCloneable: not initialized.");

        return mintFee;
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This should be empty for the 'Default' ecosystem.
     *
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }
}
