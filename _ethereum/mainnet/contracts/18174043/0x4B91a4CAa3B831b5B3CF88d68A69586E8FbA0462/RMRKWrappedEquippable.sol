//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC20.sol";
import "./ERC721Burnable.sol";
import "./RMRKMinifiedEquippable.sol";
import "./RMRKImplementationBase.sol";
import "./IRMRKWrappedEquippable.sol";

error CanOnlyReceiveTokensFromTheOriginalCollection();
error NotCollectionOwner();
error PaymentDataAlreadySet();
error TokenIdOverMaxSupply();

/**
 * @title RMRK Wrapped Equippable
 * @notice This contract represents a wrapped ERC721 collection, extended with RMRK equippable functionality. Token
 *  owners can wrap and unwrap their tokens at any time, given they pay the wrapping fee. The collection owner can
 *  prepay for all the individual token wraps when wrapping the collection. In this case no fees are charged when
 *  wrapping individual tokens.
 */
contract RMRKWrappedEquippable is
    IERC721Receiver,
    IRMRKWrappedEquippable,
    RMRKImplementationBase,
    RMRKMinifiedEquippable
{
    uint64 internal constant _LOWEST_POSSIBLE_PRIORITY = (2 ^ 64) - 1;

    // Orphan Address
    address internal constant _ORPHAN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address internal _originalCollection;
    bool internal _isZeroIndexed;
    mapping(uint256 originalTokenId => bool everWrapped)
        internal _wrappedTokens;
    mapping(uint256 originalTokenId => string tokenURI)
        internal _tokenURIPerToken;

    address internal _beneficiary;
    address internal _paymentToken;
    uint256 internal _individualWrappingPrice;

    /**
     * @notice Checks if the caller is the owner of the original collection.
     * @dev reverts if the caller is not the owner of the original collection.
     */
    modifier onlyCollectionOwner() {
        _checkCollectionOwner();
        _;
    }

    /**
     * @notice Initializes the contract.
     * @param originalCollection The address of the original collection
     * @param maxSupply_ The maximum supply of the wrapped collection
     * @param royaltiesRecipient The address of the royalties recipient
     * @param royaltyPercentageBps The royalty percentage in basis points
     * @param name The name of the collection
     * @param symbol The symbol of the collection
     * @param collectionMetadataURI The collection metadata URI
     */
    constructor(
        address originalCollection,
        uint256 maxSupply_,
        address royaltiesRecipient,
        uint256 royaltyPercentageBps,
        string memory name,
        string memory symbol,
        string memory collectionMetadataURI
    )
        RMRKImplementationBase(
            name,
            symbol,
            collectionMetadataURI,
            maxSupply_,
            royaltiesRecipient,
            royaltyPercentageBps
        )
    {
        _originalCollection = originalCollection;
    }

    /**
     * @inheritdoc IRMRKWrappedEquippable
     */
    function setPaymentData(
        address paymentToken,
        uint256 individualWrappingPrice,
        address beneficiary
    ) public onlyOwner {
        if (_paymentToken != address(0)) revert PaymentDataAlreadySet();

        _paymentToken = paymentToken;
        _individualWrappingPrice = individualWrappingPrice;
        _beneficiary = beneficiary;
    }

    /**
     * @notice Returns the address of the ERC20 token used for payment.
     * @return paymentToken The address of the ERC20 token used for payment
     */
    function getPaymentToken() public view returns (address paymentToken) {
        return _paymentToken;
    }

    /**
     * @notice Returns the individual wrapping price.
     * @return The price of wrapping a single token expressed in the lowest denomination of the currency
     */
    function getIndividualWrappingPrice() public view returns (uint256) {
        return _individualWrappingPrice;
    }

    /**
     * @notice Returns the address of the beneficiary.
     * @return The address of the beneficiary
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @notice Called by the safeTransferFrom method of the original collection.
     * @dev This is where the wrapping happens. The original token is locked in this contract and a wrapped token is
     *  minted to the original token owner.
     * @dev Reverts if tokens are not prepaid and there is not enough allowance.
     * @dev If the token is zero, it is minted with the max supply as ID. This is because the zero IDs are not allowed
     *  in RMRK implementation.
     * @param from The address of the original token owner
     * @param tokenId The ID of the original token
     * @return The ERC721ReceiveronERC721Received selector
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) external virtual returns (bytes4) {
        uint256 wrappedTokenId = tokenId;
        if (msg.sender != _originalCollection)
            revert CanOnlyReceiveTokensFromTheOriginalCollection();

        if (tokenId > _maxSupply) revert TokenIdOverMaxSupply();
        bool previouslyWrapped = wasTokenEverWrapped(tokenId);

        if (!previouslyWrapped && _individualWrappingPrice > 0) {
            IERC20(_paymentToken).transferFrom(
                from,
                _beneficiary,
                _individualWrappingPrice
            );
        }

        if (previouslyWrapped) {
            // A wrapped version was already created, it should be owned by the orphan address, we simply restore it
            _transfer(_ORPHAN_ADDRESS, from, getWrappedTokenId(tokenId), "");
        } else {
            _wrappedTokens[tokenId] = true; // Keep track for original Id
            // Mint token ID to the from. If it's zero, use max supply
            if (tokenId == 0) {
                _isZeroIndexed = true;
                wrappedTokenId = _maxSupply;
            }
            _storeTokenURI(wrappedTokenId, tokenId);
            _safeMint(from, wrappedTokenId, "");
        }

        _totalSupply++;

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Returns the URI for the given token.
     * @dev If the token has assets, it returns the URI of the asset with the highest priority. Otherwise falls back to original tokenURI.
     * @param tokenId The ID of the token
     * @return The URI of the token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        _requireMinted(tokenId);
        if (_activeAssets[tokenId].length == 0) {
            return _tokenURIPerToken[tokenId];
        } else {
            uint64[] memory priorities = getActiveAssetPriorities(tokenId);
            uint64 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
            uint64 maxPriorityAssetId;
            uint64 currentPrio;
            uint256 length = priorities.length;
            for (uint64 i; i < length; ) {
                currentPrio = priorities[i];
                if (currentPrio < maxPriority) {
                    maxPriority = currentPrio;
                    maxPriorityAssetId = _activeAssets[tokenId][i];
                }
                unchecked {
                    ++i;
                }
            }
            return getAssetMetadata(tokenId, maxPriorityAssetId);
        }
    }

    /**
     * @return Address of the original collection
     */
    function getOriginalCollection() public view returns (address) {
        return _originalCollection;
    }

    /**
     * @notice Returns true if the token was wrapped at least once before. It does not matter if it is currently wrapped or not.
     * @param tokenId The ID of the token
     * @return Whether the token was wrapped at least once before
     */
    function wasTokenEverWrapped(
        uint256 tokenId
    ) public view virtual returns (bool) {
        return _wrappedTokens[tokenId];
    }

    /**
     * @inheritdoc RMRKMinifiedEquippable
     */
    function _exists(uint256 tokenId) internal view override returns (bool) {
        bool exists = super._exists(tokenId);
        if (exists) {
            // If it is owned by the orphan address, it means it is unwrapped. Currently should count as not existing
            // Trying to do the check before reverts on some cases
            (address immediateOwner, , ) = directOwnerOf(tokenId);
            exists = immediateOwner != _ORPHAN_ADDRESS;
        }
        return exists;
    }

    /**
     * @notice Unwraps a wrapped token. It orphans the wrapped token and transfers the original token to the wrapped token
     *  owner.
     * @dev Only the owner of the wrapped token can unwrap it. It can be different from the address which wrapped it in
     *  the first place.
     * @param originalTokenId The ID of the original token
     * @param to The address of the original token owner
     */
    function unwrap(
        uint256 originalTokenId,
        address to
    ) public onlyApprovedOrDirectOwner(getWrappedTokenId(originalTokenId)) {
        uint256 wrappedTokenId = getWrappedTokenId(originalTokenId);
        _transfer(ownerOf(wrappedTokenId), _ORPHAN_ADDRESS, wrappedTokenId, "");
        _totalSupply--;
        IERC721(_originalCollection).transferFrom(
            address(this),
            to,
            originalTokenId
        );
    }

    /**
     * @notice Returns the original token ID from a wrapped token ID.
     * @dev If the token is zero, it is minted with the max supply as ID. This is because the zero IDs are not allowed
     *  in RMRK implementation.
     * @param originalTokenId The ID of the original token
     * @return wrappedTokenId The ID of the wrapped token
     */
    function getWrappedTokenId(
        uint256 originalTokenId
    ) public view returns (uint256) {
        return originalTokenId == 0 ? _maxSupply : originalTokenId;
    }

    function getOriginalTokenId(
        uint256 wrappedTokenId
    ) public view returns (uint256) {
        return
            wrappedTokenId == _maxSupply && _isZeroIndexed ? 0 : wrappedTokenId;
    }

    /**
     * @notice Returns the address of the current owner of the original collection.
     * @return Address of the current owner of the original collection
     */
    function _collectionOwner() internal view returns (address) {
        return Ownable(_originalCollection).owner();
    }

    /**
     * @notice Checks if the sender is the owner of the original collection.
     * @dev Reverts if the sender is not the owner of the original collection.
     */
    function _checkCollectionOwner() private view {
        if (_msgSender() != _collectionOwner()) revert NotCollectionOwner();
    }

    // -------------- STANDARD EQUIPPABLE LOGIC --------------

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == RMRK_INTERFACE;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (to == address(0)) {
            unchecked {
                _totalSupply -= 1;
            }
            // Will try to burn original token, it might fail if it is not burnable or has a custom burn method in which case we just ignore
            try
                ERC721Burnable(_originalCollection).burn(
                    getOriginalTokenId(tokenId)
                )
            {} catch {
                IERC721(_originalCollection).transferFrom(
                    address(this),
                    _ORPHAN_ADDRESS,
                    getOriginalTokenId(tokenId)
                );
            }
        }
    }

    /**
     * @notice Used to add a asset entry.
     * @dev The ID of the asset is automatically assigned to be the next available asset ID.
     * @param metadataURI Metadata URI of the asset
     */
    function addAssetEntry(
        string memory metadataURI
    ) public virtual onlyCollectionOwner returns (uint256) {
        unchecked {
            _totalAssets += 1;
        }
        _addAssetEntry(uint64(_totalAssets), metadataURI);
        return _totalAssets;
    }

    /**
     * @notice Used to add an equippable asset entry.
     * @dev The ID of the asset is automatically assigned to be the next available asset ID.
     * @param equippableGroupId ID of the equippable group
     * @param catalogAddress Address of the `Catalog` smart contract this asset belongs to
     * @param metadataURI Metadata URI of the asset
     * @param partIds An array of IDs of fixed and slot parts to be included in the asset
     * @return uint256 The total number of assets after this asset has been added
     */
    function addEquippableAssetEntry(
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] calldata partIds
    ) public virtual onlyCollectionOwner returns (uint256) {
        unchecked {
            _totalAssets += 1;
        }
        _addAssetEntry(
            uint64(_totalAssets),
            equippableGroupId,
            catalogAddress,
            metadataURI,
            partIds
        );
        return _totalAssets;
    }

    /**
     * @notice Used to add an asset to a token.
     * @dev If the given asset is already added to the token, the execution will be reverted.
     * @dev If the asset ID is invalid, the execution will be reverted.
     * @dev If the token already has the maximum amount of pending assets (128), the execution will be
     *  reverted.
     * @param tokenId ID of the token to add the asset to
     * @param assetId ID of the asset to add to the token
     * @param replacesAssetWithId ID of the asset to replace from the token's list of active assets
     */
    function addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) public virtual onlyCollectionOwner {
        _addAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    /**
     * @notice Used to add an asset to multiple tokens token.
     * @dev If the given asset is already added to any of the tokens, the execution will be reverted.
     * @dev If the asset ID is invalid, the execution will be reverted.
     * @dev If the token already has the maximum amount of pending assets (128), the execution will be
     *  reverted.
     * @param tokenIds IDs of the tokens to add the asset to
     * @param assetId ID of the asset to add to the tokens
     */
    function addAssetToTokens(
        uint256[] calldata tokenIds,
        uint64 assetId
    ) public virtual onlyCollectionOwner {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; ) {
            _addAssetToToken(tokenIds[i], assetId, 0);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to declare that the assets belonging to a given `equippableGroupId` are equippable into the `Slot`
     *  associated with the `partId` of the collection at the specified `parentAddress`
     * @param equippableGroupId ID of the equippable group
     * @param parentAddress Address of the parent into which the equippable group can be equipped into
     * @param partId ID of the `Slot` that the items belonging to the equippable group can be equipped into
     */
    function setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 partId
    ) public virtual onlyCollectionOwner {
        _setValidParentForEquippableGroup(
            equippableGroupId,
            parentAddress,
            partId
        );
    }

    /**
     * @inheritdoc RMRKRoyalties
     */
    function updateRoyaltyRecipient(
        address newRoyaltyRecipient
    ) public virtual override onlyCollectionOwner {
        _setRoyaltyRecipient(newRoyaltyRecipient);
    }

    function _storeTokenURI(
        uint256 wrappedTokenId,
        uint256 originalTokenId
    ) internal virtual {
        _tokenURIPerToken[wrappedTokenId] = IERC721Metadata(_originalCollection)
            .tokenURI(originalTokenId);
    }
}
