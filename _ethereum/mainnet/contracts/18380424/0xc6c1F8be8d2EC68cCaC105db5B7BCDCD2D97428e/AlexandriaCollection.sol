// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* 
      ___                     ___         ___         ___         ___        _____        ___                   ___     
     /  /\                   /  /\       /__/|       /  /\       /__/\      /  /::\      /  /\      ___        /  /\    
    /  /::\                 /  /:/_     |  |:|      /  /::\      \  \:\    /  /:/\:\    /  /::\    /  /\      /  /::\   
   /  /:/\:\  ___     ___  /  /:/ /\    |  |:|     /  /:/\:\      \  \:\  /  /:/  \:\  /  /:/\:\  /  /:/     /  /:/\:\  
  /  /:/~/::\/__/\   /  /\/  /:/ /:/_ __|__|:|    /  /:/~/::\ _____\__\:\/__/:/ \__\:|/  /:/~/:/ /__/::\    /  /:/~/::\ 
 /__/:/ /:/\:\  \:\ /  /:/__/:/ /:/ //__/::::\___/__/:/ /:/\:/__/::::::::\  \:\ /  /:/__/:/ /:/__\__\/\:\__/__/:/ /:/\:\
 \  \:\/:/__\/\  \:\  /:/\  \:\/:/ /:/  ~\~~\::::\  \:\/:/__\\  \:\~~\~~\/\  \:\  /:/\  \:\/:::::/  \  \:\/\  \:\/:/__\/
  \  \::/      \  \:\/:/  \  \::/ /:/    |~~|:|~~ \  \::/     \  \:\  ~~~  \  \:\/:/  \  \::/~~~~    \__\::/\  \::/     
   \  \:\       \  \::/    \  \:\/:/     |  |:|    \  \:\      \  \:\       \  \::/    \  \:\        /__/:/  \  \:\     
    \  \:\       \__\/      \  \::/      |  |:|     \  \:\      \  \:\       \__\/      \  \:\       \__\/    \  \:\    
     \__\/                   \__\/       |__|/       \__\/       \__\/                   \__\/                 \__\/    
 */

import "./ERC721Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./IERC4906Upgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IVersionedContract.sol";

/**
 * @dev This is an Alexandria collection.
 *      For more info or to publish your own Alexandria collection, visit alexandrialabs.xyz.
 */
/// @custom:security-contact tech@alexandrialabs.xyz
contract AlexandriaCollection is
    Initializable,
    ERC721Upgradeable,
    IERC4906Upgradeable,
    ERC2981Upgradeable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IVersionedContract
{
    // Accounts
    address public publisher;
    address public platformAdmin;

    // Roles for Access Control
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TOKEN_URI_ROLE = keccak256("TOKEN_URI_ROLE");
    bytes32 public constant PRICE_ROLE = keccak256("PRICE_ROLE");
    bytes32 public constant AVAILABLE_TO_MINT_ROLE = keccak256("AVAILABLE_TO_MINT_ROLE");
    bytes32 public constant PUBLISHER_RESERVE_ROLE = keccak256("PUBLISHER_RESERVE_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Collection-level metadata for OpenSea (https://docs.opensea.io/docs/contract-level-metadata)
    string public contractURI;

    // Flag to indicate that metadata has been frozen
    bool public metadataFrozen;

    struct CollectionParameters {
        uint256 maxSupply;
        uint256 availableToMintDate;
        uint256 price;
        uint256 walletLimit; // Set to 0 for unlimited
        uint96 secondaryRoyaltyPercentage; // Specified in basis points, e.g. 700 = 7%
    }
    CollectionParameters public collectionParameters;

    // The baseTokenURI for all tokens in this collection
    string private _baseTokenURI;

    // The current tokenId counter
    uint256 private _currentTokenId;

    // Keep track of total funds released to the publisher account
    uint256 public totalFundsReleased;

    // Event to indicate the collection has been initialized
    event CollectionInitialized(
        address indexed collectionAddress,
        string name,
        string symbol,
        string baseTokenURI,
        string contractURI,
        CollectionParameters collectionParameters,
        address indexed publisher,
        address indexed platformAdmin
    );

    // Events to indicate collection parameters have been changed
    event AvailableToMintDateChanged(uint256 newAvailableToMintDate);
    event PriceChanged(uint256 newPrice);

    // Event to indicate the baseTokenURI has been updated
    event BaseTokenURIUpdated(string newBaseTokenURI);

    // Event for releasing funds
    event FundsReleased(address indexed to, uint256 amount);

    // Event for metadata freeze
    event MetadataFrozen();

    // Custom errors related to availableToMint
    error NotYetAvailableToMint(uint256 availableToMintDate);
    error AlreadyAvailableToMint();

    // Custom errors related to minting
    error SoldOut();
    error WalletLimitExceeded(uint256 tokensRequested, uint256 tokensInWallet, uint256 walletLimit);
    error NotEnoughRemaining(uint256 tokensRequested, uint256 tokensRemaining);
    error IncorrectPaymentAmount(uint256 amountSent, uint256 amountRequired);

    // Custom errors related to releasing funds
    error BalanceIsZero();
    error ReleaseFundsError();

    // Custom error related to freezing metadata
    error MetadataIsFrozen();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the AlexandriaCollection.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        string memory contractURI_,
        CollectionParameters memory collectionParameters_,
        address publisher_,
        address platformAdmin_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __ERC2981_init();
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        collectionParameters = collectionParameters_;
        contractURI = contractURI_;
        _baseTokenURI = baseTokenURI_;

        // Accounts
        publisher = publisher_;
        platformAdmin = platformAdmin_;

        // Set up Access Control
        _grantRole(DEFAULT_ADMIN_ROLE, platformAdmin);
        _grantRole(PAUSER_ROLE, platformAdmin);
        _grantRole(UPGRADER_ROLE, platformAdmin);
        _grantRole(OWNER_ROLE, publisher);
        _grantRole(TOKEN_URI_ROLE, publisher);
        _grantRole(AVAILABLE_TO_MINT_ROLE, publisher);
        _grantRole(PUBLISHER_RESERVE_ROLE, publisher);
        _grantRole(PRICE_ROLE, publisher);

        // Set the secondary royalty per ERC2981
        _setDefaultRoyalty(
            getRoleMember(OWNER_ROLE, 0),
            collectionParameters.secondaryRoyaltyPercentage
        );

        emit CollectionInitialized(
            address(this),
            name_,
            symbol_,
            baseTokenURI_,
            contractURI_,
            collectionParameters_,
            publisher_,
            platformAdmin_
        );
    }

    /**
     * @dev Mint tokens from the collection.
     *
     * @param tokens The number of tokens to mint.
     * @param to The address to mint to.
     */
    function mint(uint256 tokens, address to) external payable onlyWalletLimitNotExceeded(tokens, to) {
        if (!availableToMint()) revert NotYetAvailableToMint(collectionParameters.availableToMintDate);
        _checkSupply(tokens);
        if (msg.value != collectionParameters.price * tokens) {
            revert IncorrectPaymentAmount(msg.value, collectionParameters.price * tokens);
        }

        _mintTokens(tokens, to);
    }

    /**
     * @dev Mint tokens to the publisher reserve.
     *
     * @param tokens The number of tokens to mint.
     * @param to The address to mint to.
     */
    function mintPublisherReserve(uint256 tokens, address to) external onlyRole(PUBLISHER_RESERVE_ROLE) {
        _checkSupply(tokens);
        _mintTokens(tokens, to);
    }

    /**
     * @dev Check the remaining supply.
     */
    function _checkSupply(uint256 tokens) internal view {
        if (remainingSupply() == 0) revert SoldOut();
        if (tokens > remainingSupply()) revert NotEnoughRemaining(tokens, remainingSupply());
    }

    /**
     * @dev Mint the tokens.
     */
    function _mintTokens(uint256 tokens, address to) internal {
        for (uint256 i = 0; i < tokens; i++) {
            ++_currentTokenId; // tokenIds start at 1
            _safeMint(to, _currentTokenId);
        }
    }

    /**
     * @dev Mint eligibility method for use with Paper (https://withpaper.com).
     *
     * Since we use custom errors, this optional method allows Paper to check
     * mint eligibility and return a user-friendly error message to the user.
     *
     * @return An error string if the mint is not eligible, or an empty string if the mint is eligible.
     */
    function checkMintEligibility(uint256 tokens, address to) external view returns (string memory) {
        if (!availableToMint()) {
            return "Minting not yet live";
        } else if (paused()) {
            return "Minting is paused";
        } else if (remainingSupply() == 0) {
            return "Sold out";
        } else if (tokens > remainingSupply()) {
            return "Not enough remaining";
        } else if (checkWalletLimitExceeded(tokens, to)) {
            return "Wallet limit exceeded";
        } else return ""; // All good
    }

    /**
        @dev Returns the total number of tokens minted so far.
     */
    function totalSupply() external view returns (uint256) {
        return _currentTokenId;
    }

    /**
     * @dev Returns the number of tokens in the collection remaining to be minted.
     */
    function remainingSupply() public view returns (uint256) {
        return collectionParameters.maxSupply - _currentTokenId;
    }

    /**
     * @dev Returns true if the available to mint date has passed.
     */
    function availableToMint() public view returns (bool) {
        return block.timestamp >= collectionParameters.availableToMintDate;
    }

    /**
     * @dev Return the amount of funds available to be released.
     */
    function releasableFunds() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     *  @dev Update the baseTokenURI value and emit a BatchMetadataUpdate event to indicate
     *  that all tokens should have their metadata refreshed in marketplaces, etc. The
     *  baseTokenURI cannot be updated after the metadata has been frozen.
     *
     *  See ERC4906 for more info on the BatchMetadataUpdate event.
     *
     * @param newBaseTokenURI The new baseTokenURI value.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyRole(TOKEN_URI_ROLE) {
        if (metadataFrozen) revert MetadataIsFrozen();
        _baseTokenURI = newBaseTokenURI;
        if (_currentTokenId > 0) {
            emit BatchMetadataUpdate(1, _currentTokenId);
        }
        emit BaseTokenURIUpdated(newBaseTokenURI);
    }

    /**
     * @dev Freeze the metadata for this collection.
     *
     * This is a one-way operation and cannot be undone.
     */
    function freezeMetadata() external onlyRole(TOKEN_URI_ROLE) {
        if (metadataFrozen) revert MetadataIsFrozen();
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    /**
     * @dev Allow the holder of the AVAILABLE_TO_MINT_ROLE to update the availableToMintDate
     * if they prefer to manually control the actual moment their collection goes on sale.
     *
     * Set this value to zero to shortcut any previous future release date and
     * make the collection available to mint immediately.
     *
     * Set the date further into the future to extend the release date.
     *
     * If the collection is already available to mint, this value can no longer
     * be updated and we revert with an error.
     *
     * @param newAvailableToMintDate The new availableToMintDate.
     */
    function setAvailableToMintDate(
        uint256 newAvailableToMintDate
    ) external onlyRole(AVAILABLE_TO_MINT_ROLE) {
        if (availableToMint()) revert AlreadyAvailableToMint();
        collectionParameters.availableToMintDate = newAvailableToMintDate;
        emit AvailableToMintDateChanged(newAvailableToMintDate);
    }

    /**
     * @dev Allow the holder of the PRICE_ROLE to update the price.
     *
     * @param newPrice The new price.
     */
    function setPrice(uint256 newPrice) external onlyRole(PRICE_ROLE) {
        collectionParameters.price = newPrice;
        emit PriceChanged(newPrice);
    }

    /**
     * @dev Allow the holder of the PAUSER_ROLE to pause the contract.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Allow the holder of the PAUSER_ROLE to unpause the contract.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Allow contract funds to be released to the publisher account.
     */
    function releaseFunds() external {
        uint256 amount = address(this).balance;
        if (amount == 0) {
            revert BalanceIsZero();
        }
        (bool success, ) = payable(publisher).call{value: amount}("");
        if (!success) {
            revert ReleaseFundsError();
        }
        totalFundsReleased += amount;
        emit FundsReleased(publisher, amount);
    }

    /**
     * @dev Implement the Ownable.owner() function here because it is required by OpenSea to allow
     * the publisher to edit their collection there. OpenSea uses Ownable only and NOT AccessControl
     * for verifying ownership.
     *
     * @return An AccessControl equivalent of Ownable's owner, specified as OWNER_ROLE.
     */
    function owner() public view returns (address) {
        return getRoleMember(OWNER_ROLE, 0);
    }

    /**
     * @dev Modifier for checking the wallet limit. Reverts if the wallet limit is exceeded.
     */
    modifier onlyWalletLimitNotExceeded(uint256 tokens, address to) {
        if (checkWalletLimitExceeded(tokens, to))
            revert WalletLimitExceeded(tokens, balanceOf(to), collectionParameters.walletLimit);
        _;
    }

    /**
     * @dev Check to ensure that the wallet limit is not exceeded. A wallet limit value of zero
     * indicates unlimited.
     *
     * @return true if the wallet limit is exceeded, false otherwise.
     */
    function checkWalletLimitExceeded(uint256 tokens, address to) internal view returns (bool) {
        return
            (collectionParameters.walletLimit != 0) &&
            (tokens + balanceOf(to) > collectionParameters.walletLimit);
    }

    /**
     * @dev See {ERC721Upgradeable-_baseURI}.
     *      Override to implement a baseTokenURI for all tokenIDs.
     *
     * @return The baseTokenURI value.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC721Upgradeable-_beforeTokenTransfer}.
     *      This is where Pausable hooks into mints and transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     *      Only the holder of the UPGRADER_ROLE can upgrade.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev See {IVersionedContract-contractType}.
     */
    function contractType() external pure override returns (bytes32) {
        return bytes32("AlexandriaCollection");
    }

    /**
     * @dev See {IVersionedContract-contractVersion}.
     */
    function contractVersion() external pure override returns (bytes8) {
        return bytes8("1.0.0");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC2981Upgradeable,
            AccessControlEnumerableUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        // Implement ERC-4906's interfaceId as 0x49064906, see https://eips.ethereum.org/EIPS/eip-4906
        // and OpenZeppelin's ERC721URIStorageUpgradeable
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
