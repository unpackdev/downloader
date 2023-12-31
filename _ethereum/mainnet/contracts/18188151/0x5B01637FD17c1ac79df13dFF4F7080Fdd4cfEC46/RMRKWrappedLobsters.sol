//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "./Strings.sol";
import "./RMRKWrappedEquippable.sol";

/**
 * @title RMRK Wrapped Equippable With Preloaded Token URI
 * @notice This contract represents a wrapped ERC721 collection, extended with RMRK equippable functionality. Token
 *  owners can wrap and unwrap their tokens at any time, given they pay the wrapping fee. The collection owner can
 *  prepay for all the individual token wraps when wrapping the collection. In this case no fees are charged when
 *  wrapping individual tokens. TokenURI is preloaded by admins instead of querying it live from the original collection.
 */
contract RMRKWrappedLobsters is RMRKWrappedEquippable {
    error TokenURINotYetPreloaded();

    mapping(uint256 originalTokenId => uint256 tokenURI)
        internal _preloadedTokenURIPerToken;

    string private _baseURI;

    constructor(
        address originalCollection,
        uint256 maxSupply_,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory name,
        string memory symbol,
        string memory collectionMetadataURI,
        string memory baseURI
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
    {
        _baseURI = baseURI;
    }

    function getPreloadedTokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        uint256 initToken = (tokenId >> 4) << 4; // Divide by 16 and multiply by 16 to get the smallest token id in the range
        uint256 tokenURIs = _preloadedTokenURIPerToken[initToken];
        uint256 actualTokenURI = (tokenURIs >> ((tokenId - initToken) * 16)) &
            0xFFFF;
        if (tokenURIs == 0) {
            // Cannot check on actualTokenURI because it could be 0
            revert TokenURINotYetPreloaded();
        }
        return string.concat(_baseURI, Strings.toString(actualTokenURI));
    }

    function setPreloadedTokenURIs(
        uint256 tokenIds,
        uint256 tokenURIs
    ) external onlyOwnerOrContributor {
        // Every 16 bits there is a token id and a token URI. It is referenced by the smallest token id in the range which should be on the right most position
        uint256 initToken = tokenIds & 0xFFFF; // Get the smallest token id in the range
        _preloadedTokenURIPerToken[initToken] = tokenURIs;
    }

    function _storeTokenURI(
        uint256 wrappedTokenId,
        uint256 originalTokenId
    ) internal virtual override {
        _tokenURIPerToken[wrappedTokenId] = getPreloadedTokenURI(
            originalTokenId
        );
    }
}
