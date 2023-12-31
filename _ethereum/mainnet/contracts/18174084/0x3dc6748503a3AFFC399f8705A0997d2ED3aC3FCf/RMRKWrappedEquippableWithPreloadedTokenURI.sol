//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "./RMRKWrappedEquippable.sol";

/**
 * @title RMRK Wrapped Equippable With Preloaded Token URI
 * @notice This contract represents a wrapped ERC721 collection, extended with RMRK equippable functionality. Token
 *  owners can wrap and unwrap their tokens at any time, given they pay the wrapping fee. The collection owner can
 *  prepay for all the individual token wraps when wrapping the collection. In this case no fees are charged when
 *  wrapping individual tokens. TokenURI is preloaded by admins instead of querying it live from the original collection.
 */
contract RMRKWrappedEquippableWithPreloadedTokenURI is RMRKWrappedEquippable {
    error TokenURINotYetPreloaded();
    error TokenURIAlreadyPreloaded();
    error LengthMissmatch();

    mapping(uint256 originalTokenId => string tokenURI)
        internal _preloadedTokenURIPerToken;

    constructor(
        address originalCollection,
        uint256 maxSupply_,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory name,
        string memory symbol,
        string memory collectionMetadataURI
    )
        RMRKWrappedEquippable(
            originalCollection,
            maxSupply_,
            royaltiesRecipient,
            royaltyPercentageBps,
            name,
            symbol,
            collectionMetadataURI
        )
    {}

    function getPreloadedTokenURI(
        uint256 tokenId
    ) external view returns (string memory) {
        return _preloadedTokenURIPerToken[tokenId];
    }

    function setPreloadedTokenURIs(
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) external onlyOwnerOrContributor {
        uint256 length = tokenIds.length;
        if (length != tokenURIs.length) revert LengthMissmatch();
        for (uint256 i; i < length; ) {
            if (bytes(_tokenURIPerToken[tokenIds[i]]).length != 0) {
                // Guarantee that it will not be replaced after minted. It is fine if it is replaced before minted.
                revert TokenURIAlreadyPreloaded();
            }
            _preloadedTokenURIPerToken[tokenIds[i]] = tokenURIs[i];
            unchecked {
                ++i;
            }
        }
    }

    function _storeTokenURI(
        uint256 wrappedTokenId,
        uint256 originalTokenId
    ) internal virtual override {
        if (bytes(_preloadedTokenURIPerToken[originalTokenId]).length == 0) {
            revert TokenURINotYetPreloaded();
        }
        _tokenURIPerToken[wrappedTokenId] = _preloadedTokenURIPerToken[
            originalTokenId
        ];
    }
}
