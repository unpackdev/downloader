// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ICollectionNFTEligibilityPredicate.sol";
import "./IHashes.sol";
import "./ICollection.sol";

/**
 * @title  DAOHashesEligibilityPredicate
 * @author David Matheson
 * @notice This is a helper contract used to determine token eligibility upon instantiating a new
 *         contract from CollectionNFTCloneableV1 to create a new Hashes NFT collection.
 *         This contract includes a function, isTokenEligibleToMint, where a tokenId
 *         and hashesTokenId is provided and the internal logic then determines if hashesTokenId
 *         is a DAO token and not deactivated.
 */
contract DAOHashesEligibilityPredicate is ICollectionNFTEligibilityPredicate, ICollection {
    IHashes hashesToken;

    constructor(IHashes _hashesToken) {
        hashesToken = _hashesToken;
    }

    /**
     * @notice This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a specified hashes collection by validating if the hashes token Id is a governance token and
     *          has not been deactivated. This function is to be used when instantiating new hashes collections
     *          where only DAO hash holders are eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The boolean result of the validation.
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
        return _hashesTokenId < hashesToken.governanceCap() && !hashesToken.deactivated(_hashesTokenId);
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
