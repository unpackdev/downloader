// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

//  ==========  External imports    ==========

import "./Multicall.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

import "./ERC721EnumerableUpgradeable.sol";

//  ==========  Internal imports    ==========

import "./CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "./ContractMetadata.sol";
import "./PlatformFee.sol";
import "./RoyaltyMigration.sol";
import "./PrimarySale.sol";
import "./Ownable.sol";
import "./LazyMint.sol";
import "./PermissionsEnumerable.sol";
import "./Drop.sol";

import "./TokenMigrateERC721.sol";

contract DropERC721M is
    Initializable,
    ContractMetadata,
    PlatformFee,
    RoyaltyMigration,
    PrimarySale,
    Ownable,
    LazyMint,
    PermissionsEnumerable,
    Drop,
    Multicall,
    ERC721EnumerableUpgradeable,
    TokenMigrateERC721
{
    using StringsUpgradeable for uint256;

    /// @dev Unable to transfer the token due to missing role
    error DropTransferRestricted(address from, address to);

    /// @dev Invalid msg.value
    error DropInvalidMsgValue(uint256 expected, uint256 actual);

    /// @dev token owner or approved
    error DropNotApprovedOrOwner(address sender, uint256 tokenId);

    /// @dev failed to lazy mint with delay reveal
    error DropDelayRevealUnsupported();

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only METADATA_ROLE holders can reveal the URI to update or freeze batch metadata.
    bytes32 private constant METADATA_ROLE = keccak256("METADATA_ROLE");
    /// @dev Only MIGRATION_ROLE holders for setting migration merkle root
    bytes32 private constant MIGRATION_ROLE = keccak256("MIGRATION_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Global max total supply of NFTs.
    uint256 public maxTotalSupply;

    /// @dev Next tokenId to be claimed.
    uint256 public nextTokenIdToClaim;

    /// @dev Next tokenId that was to be claimed on original contract.
    uint256 private migratedNextTokenId;

    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor() initializer {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        address __originalContract,
        bytes32 _ownershipMerkleRoot,
        string memory _contractURI
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC721_init(DropERC721M(__originalContract).name(), DropERC721M(__originalContract).symbol());

        {
            _setupOriginalContract(__originalContract);
            _setupMerkleRoot(_ownershipMerkleRoot);

            uint256 _nextIdToClaim = DropERC721M(_originalContract).nextTokenIdToClaim();
            uint256 _nextIdToMint = DropERC721M(_originalContract).nextTokenIdToMint();
            nextTokenIdToClaim = _nextIdToClaim;
            nextTokenIdToLazyMint = _nextIdToMint;
            migratedNextTokenId = _nextIdToMint;

            (address royaltyRecipient, uint16 royaltyBps) = DropERC721M(__originalContract).getDefaultRoyaltyInfo();
            (address platformFeeRecipient, uint256 platformFeeBps) = DropERC721M(__originalContract)
                .getPlatformFeeInfo();
            address primarySaleRecipient = DropERC721M(__originalContract).primarySaleRecipient();

            if (platformFeeRecipient != address(0)) {
                _setupPlatformFeeInfo(platformFeeRecipient, platformFeeBps);
            }

            if (royaltyRecipient != address(0)) {
                _setupDefaultRoyaltyInfo(royaltyRecipient, royaltyBps);
            }

            if (primarySaleRecipient != address(0)) {
                _setupPrimarySaleRecipient(primarySaleRecipient);
            }
        }

        try DropERC721M(__originalContract).maxTotalSupply() returns (uint256 _maxTotalSupply) {
            maxTotalSupply = _maxTotalSupply;
        } catch {}

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);

        _setupRole(TRANSFER_ROLE, address(0));

        _setupRole(METADATA_ROLE, _defaultAdmin);
        _setRoleAdmin(METADATA_ROLE, METADATA_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId < migratedNextTokenId) {
            return DropERC721M(_originalContract).tokenURI(_tokenId);
        }
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*///////////////////////////////////////////////////////////////
                            Migration logic
    //////////////////////////////////////////////////////////////*/

    function _mintMigratedTokens(address _to, uint256 _tokenId) internal virtual override {
        _safeMint(_to, _tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                                ERC165
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721EnumerableUpgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                        Contract identifiers
    //////////////////////////////////////////////////////////////*/

    function contractType() external pure returns (bytes32) {
        return bytes32("DropERC721M");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(4);
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *       The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     */
    function lazyMint(
        uint256 _amount,
        string calldata _baseURIForTokens,
        bytes calldata _data
    ) public override returns (uint256 batchId) {
        if (_data.length > 0) {
            revert DropDelayRevealUnsupported();
        }
        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /**
     *  @notice          View royalty info for a given token.
     *  @dev             Returns royalty recipient and bps for `_tokenId`.
     *  @param _tokenId  The tokenID of the NFT for which to query royalty info.
     */
    function getRoyaltyInfoForToken(uint256 _tokenId) public view override returns (address, uint16) {
        RoyaltyInfo memory royaltyForToken = royaltyInfoForToken[_tokenId];

        // if it's a migrated token and royalty has not been overriden yet
        if (_tokenId < migratedNextTokenId && royaltyForToken.recipient == address(0) && royaltyForToken.bps == 0) {
            return IRoyalty(_originalContract).getRoyaltyInfoForToken(_tokenId);
        }

        return
            royaltyForToken.recipient == address(0)
                ? (royaltyRecipient, uint16(royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /**
     * @notice Updates the base URI for a batch of tokens.
     *
     * @param _index Index of the desired batch in batchIds array
     * @param _uri   the new base URI for the batch.
     */
    function updateBatchBaseURI(uint256 _index, string calldata _uri) external onlyRole(METADATA_ROLE) {
        uint256 batchId = getBatchIdAtIndex(_index);
        _setBaseURI(batchId, _uri);
    }

    /**
     * @notice Freezes the base URI for a batch of tokens.
     *
     * @param _index Index of the desired batch in batchIds array.
     */
    function freezeBatchBaseURI(uint256 _index) external onlyRole(METADATA_ROLE) {
        uint256 batchId = getBatchIdAtIndex(_index);
        _freezeBaseURI(batchId);
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a contract admin set the global maximum supply for collection's NFTs.
    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_maxTotalSupply);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        if (nextTokenIdToClaim + _quantity > nextTokenIdToLazyMint) {
            revert DropExceedMaxSupply();
        }

        if (maxTotalSupply != 0 && nextTokenIdToClaim + _quantity > maxTotalSupply) {
            revert DropExceedMaxSupply();
        }
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            if (msg.value != 0) {
                revert DropInvalidMsgValue(0, msg.value);
            }
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert DropInvalidMsgValue(totalPrice, msg.value);
            }
        } else {
            if (msg.value != 0) {
                revert DropInvalidMsgValue(0, msg.value);
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, msg.sender, saleRecipient, totalPrice - platformFees);
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(
        address _to,
        uint256 _quantityBeingClaimed
    ) internal override returns (uint256 tokenIdToClaim) {
        tokenIdToClaim = nextTokenIdToClaim;

        for (uint256 i = 0; i < _quantityBeingClaimed; i += 1) {
            _safeMint(_to, tokenIdToClaim);
            tokenIdToClaim += 1;
        }

        nextTokenIdToClaim = tokenIdToClaim;
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Returns whether merkle root can be set in the given execution context.
    function _canSetMerkleRoot() internal virtual override returns (bool) {
        return hasRole(MIGRATION_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        return nextTokenIdToClaim;
    }

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert DropNotApprovedOrOwner(msg.sender, tokenId);
        }

        _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(TRANSFER_ROLE, from) && !hasRole(TRANSFER_ROLE, to)) {
                revert DropTransferRestricted(from, to);
            }
        }
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return msg.sender;
    }
}
