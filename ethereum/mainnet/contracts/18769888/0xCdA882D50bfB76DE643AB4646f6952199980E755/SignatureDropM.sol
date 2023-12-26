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
import "./RoyaltyDefaultOnly.sol";
import "./PlatformFee_V1.sol";
import "./PrimarySale_V1.sol";
import "./Ownable.sol";
import "./DelayedReveal.sol";
import "./LazyMint.sol";
import "./PermissionsEnumerable.sol";
import "./DropSinglePhase.sol";
import "./SignatureMintERC721Upgradeable.sol";

import "./TokenMigrateERC721.sol";

contract SignatureDropM is
    Initializable,
    ContractMetadata,
    PlatformFee,
    RoyaltyDefaultOnly,
    PrimarySale,
    Ownable,
    LazyMint,
    PermissionsEnumerable,
    DropSinglePhase,
    SignatureMintERC721Upgradeable,
    Multicall,
    ERC721EnumerableUpgradeable,
    TokenMigrateERC721
{
    using StringsUpgradeable for uint256;

    error SignatureDropTransferRestricted(address from, address to);
    error SignatureDropInvalidMsgValue(uint256 expected, uint256 actual);
    error SignatureDropNotApprovedOrOwner(address sender, uint256 tokenId);
    error SignatureDropExceedMaxSupply(uint256 expected, uint256 actual);
    error SignatureDropPerTokenRoyaltyUnsupported();
    error SignatureDropDelayRevealUnsupported();

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only MIGRATION_ROLE holders can sign off on `MintRequest`s and lazy mint tokens.
    bytes32 private constant MIGRATION_ROLE = keccak256("MIGRATION_ROLE");

    /// @dev Max bps in the thirdweb system.
    uint256 private constant MAX_BPS = 10_000;

    /// @dev Next tokenId that was to be claimed on original contract.
    uint256 private migratedNextTokenId;

    /// @dev Next tokenId to be claimed.
    uint256 public nextTokenIdToClaim;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        address __originalContract,
        bytes32 _ownershipMerkleRoot,
        string memory _contractURI
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ERC721_init(SignatureDropM(__originalContract).name(), SignatureDropM(__originalContract).symbol());
        __SignatureMintERC721_init();

        {
            _setupOriginalContract(__originalContract);
            _setupMerkleRoot(_ownershipMerkleRoot);

            uint256 _nextIdToClaim = SignatureDropM(__originalContract).totalMinted();
            nextTokenIdToLazyMint = SignatureDropM(__originalContract).nextTokenIdToMint();
            nextTokenIdToClaim = _nextIdToClaim;
            migratedNextTokenId = _nextIdToClaim;

            (address royaltyRecipient, uint16 royaltyBps) = SignatureDropM(__originalContract).getDefaultRoyaltyInfo();
            (address platformFeeRecipient, uint256 platformFeeBps) = SignatureDropM(__originalContract)
                .getPlatformFeeInfo();
            address primarySaleRecipient = SignatureDropM(__originalContract).primarySaleRecipient();

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

        _setupRole(MIGRATION_ROLE, _defaultAdmin);
        _setRoleAdmin(MIGRATION_ROLE, MIGRATION_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId < migratedNextTokenId) {
            return SignatureDropM(_originalContract).tokenURI(_tokenId);
        }

        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721EnumerableUpgradeable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function contractType() external pure returns (bytes32) {
        return bytes32("SignatureDropM");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

    /*///////////////////////////////////////////////////////////////
                            Migration logic
    //////////////////////////////////////////////////////////////*/

    function _mintMigratedTokens(address _to, uint256 _tokenId) internal virtual override {
        _safeMint(_to, _tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                    Lazy minting + delayed-reveal logic
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
            revert SignatureDropDelayRevealUnsupported();
        }
        return super.lazyMint(_amount, _baseURIForTokens, _data);
    }

    /*///////////////////////////////////////////////////////////////
                    Claiming lazy minted tokens logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Claim lazy minted tokens via signature.
    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable returns (address signer) {
        uint256 tokenIdToMint = nextTokenIdToClaim;
        if (tokenIdToMint + _req.quantity > nextTokenIdToLazyMint) {
            revert SignatureDropExceedMaxSupply(nextTokenIdToLazyMint, tokenIdToMint + _req.quantity);
        }

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        address receiver = _req.to;

        // Collect price
        _collectPriceOnClaim(_req.primarySaleRecipient, _req.quantity, _req.currency, _req.pricePerToken);

        // Set royalties, if applicable.
        if (_req.royaltyRecipient != address(0) && _req.royaltyBps != 0) {
            revert SignatureDropPerTokenRoyaltyUnsupported();
        }

        // Mint tokens.
        for (uint256 i = 0; i < _req.quantity; i += 1) {
            _mint(receiver, tokenIdToMint);
            tokenIdToMint += 1;
        }
        nextTokenIdToClaim = tokenIdToMint;

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint - _req.quantity, _req);
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
                revert SignatureDropInvalidMsgValue(0, msg.value);
            }
            return;
        }

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert SignatureDropInvalidMsgValue(totalPrice, msg.value);
            }
        } else {
            if (msg.value != 0) {
                revert SignatureDropInvalidMsgValue(0, msg.value);
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

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(MINTER_ROLE, _signer);
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

    /// @notice Returns whether the caller address needs to be verified.
    function _requireVerification() internal view virtual override returns (bool) {
        return !hasRole(MIGRATION_ROLE, msg.sender);
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
    function burn(uint256 tokenId) external virtual {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert SignatureDropNotApprovedOrOwner(msg.sender, tokenId);
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
                revert SignatureDropTransferRestricted(from, to);
            }
        }
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return msg.sender;
    }
}
