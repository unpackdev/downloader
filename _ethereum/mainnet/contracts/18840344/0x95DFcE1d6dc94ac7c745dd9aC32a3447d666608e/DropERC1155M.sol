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

import "./ERC1155Upgradeable.sol";

import "./Multicall.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

//  ==========  Internal imports    ==========

import "./CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "./PlatformFee_V1.sol";
import "./ContractMetadata.sol";
import "./RoyaltyMigration.sol";
import "./PrimarySale.sol";
import "./Ownable.sol";
import "./LazyMint.sol";
import "./PermissionsEnumerable.sol";
import "./Drop1155.sol";

import "./TokenMigrateERC1155.sol";

contract DropERC1155M is
    Initializable,
    ContractMetadata,
    PlatformFee,
    RoyaltyMigration,
    PrimarySale,
    Ownable,
    LazyMint,
    PermissionsEnumerable,
    Drop1155,
    Multicall,
    ERC1155Upgradeable,
    TokenMigrateERC1155
{
    using StringsUpgradeable for uint256;

    /// @dev Unable to transfer the token due to missing role
    error DropTransferRestricted(address from, address to);

    /// @dev Invalid msg.value
    error DropInvalidMsgValue(uint256 expected, uint256 actual);

    /// @dev token owner or approved
    error DropNotApprovedOrOwner(address sender);

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only METADATA_ROLE holders can reveal the URI for a batch of delayed reveal NFTs, and update batch metadata.
    bytes32 private constant METADATA_ROLE = keccak256("METADATA_ROLE");
    /// @dev Only MIGRATION_ROLE holders for setting migration merkle root
    bytes32 private constant MIGRATION_ROLE = keccak256("MIGRATION_ROLE");

    /// @dev Next tokenId that was to be claimed on original contract.
    uint256 private migratedNextTokenId;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public maxTotalSupply;

    /*///////////////////////////////////////////////////////////////
                               Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);

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
        __ERC1155_init_unchained("");

        name = DropERC1155M(__originalContract).name();
        symbol = DropERC1155M(__originalContract).symbol();

        {
            _setupOriginalContract(__originalContract);
            _setupMerkleRoot(_ownershipMerkleRoot);

            uint256 _nextId = DropERC1155M(__originalContract).nextTokenIdToMint();
            nextTokenIdToLazyMint = _nextId;
            migratedNextTokenId = _nextId;

            for (uint256 i = 0; i < _nextId; i++) {
                maxTotalSupply[i] = DropERC1155M(__originalContract).maxTotalSupply(i);
            }

            (address royaltyRecipient, uint16 royaltyBps) = DropERC1155M(__originalContract).getDefaultRoyaltyInfo();
            (address platformFeeRecipient, uint256 platformFeeBps) = DropERC1155M(__originalContract)
                .getPlatformFeeInfo();
            address primarySaleRecipient = DropERC1155M(__originalContract).primarySaleRecipient();

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

        _setupContractURI(_contractURI);
        _setupOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);

        _setupRole(TRANSFER_ROLE, address(0));

        _setupRole(METADATA_ROLE, _defaultAdmin);
        _setRoleAdmin(METADATA_ROLE, METADATA_ROLE);

        _setupRole(MIGRATION_ROLE, _defaultAdmin);
        _setRoleAdmin(MIGRATION_ROLE, MIGRATION_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Migration functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether merkle root can be set in the given execution context.
    function _canSetMerkleRoot() internal virtual override returns (bool) {
        return hasRole(MIGRATION_ROLE, msg.sender);
    }

    /// @notice Mints migrated token to token owner.
    function _mintMigratedTokens(address _tokenOwner, uint256 _tokenId, uint256 _amount) internal virtual override {
        _checkMaxTotalSupply(_tokenId, _amount);
        _mint(_tokenOwner, _tokenId, _amount, "");
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 1155 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the uri for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId < migratedNextTokenId) {
            return ERC1155Upgradeable(_originalContract).uri(_tokenId);
        }
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /*///////////////////////////////////////////////////////////////
                        Setter functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Lets a module admin set a max total supply for token.
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply[_tokenId] = _maxTotalSupply;
        emit MaxTotalSupplyUpdated(_tokenId, _maxTotalSupply);
    }

    /**
     * @notice Updates the base URI for a batch of tokens.
     *
     * @param _index Index of the desired batch in batchIds array.
     * @param _uri   the new base URI for the batch.
     */
    function updateBatchBaseURI(uint256 _index, string calldata _uri) external onlyRole(METADATA_ROLE) {
        uint256 batchId = getBatchIdAtIndex(_index);
        _setBaseURI(batchId, _uri);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        uint256 _tokenId,
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        _checkMaxTotalSupply(_tokenId, _quantity);
    }

    function _checkMaxTotalSupply(uint256 _tokenId, uint256 _quantity) internal view {
        if (maxTotalSupply[_tokenId] != 0 && totalSupply[_tokenId] + _quantity > maxTotalSupply[_tokenId]) {
            revert DropExceedMaxSupply();
        }
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectPriceOnClaim(
        uint256,
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
        uint256 platformFees = (totalPrice * platformFeeBps) / 10_000;

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
    function transferTokensOnClaim(address _to, uint256 _tokenId, uint256 _quantityBeingClaimed) internal override {
        _mint(_to, _tokenId, _quantityBeingClaimed, "");
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

    /// @notice Returns whether the caller address needs to be verified.
    function _requireVerification() internal view virtual override returns (bool) {
        return !hasRole(MIGRATION_ROLE, msg.sender);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev The tokenId of the next NFT that will be minted / lazy minted.
    function nextTokenIdToMint() external view returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        if (account != msg.sender && !isApprovedForAll(account, msg.sender)) {
            revert DropNotApprovedOrOwner(msg.sender);
        }

        _burnBatch(account, ids, values);
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
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(TRANSFER_ROLE, from) && !hasRole(TRANSFER_ROLE, to)) {
                revert DropTransferRestricted(from, to);
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return msg.sender;
    }
}
