// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

/// @title XNFT Base Contract
/// @author Wilson A.
/// @notice Used as base contract for XNFTFactory
abstract contract XNFTBase is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using StringsUpgradeable for uint256;

    struct AccountInfo {
        uint256 mintTimestamp;
        uint256 revealTimestamp;
        uint32 maxMintCount;
        uint32 maxMintPerWallet;
        uint256 mintPrice;
        address accountFeeAddress;
        bytes32 accountNameHash;
    }

    struct AccountAddressInfo {
        address xnftCloneAddr;
        address xnftLPAddr;
    }

    uint32 internal constant FEE_DENOMINATOR = 10_000;
    uint32 internal constant MAX_FEE_BPS = 1_000;
    address public constant wethAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 internal accountId;
    address internal _operator;
    address internal _xnftBeacon;
    address internal _xnftLPBeacon;

    address public marketplaceFeeAddress;
    bytes4 public marketplaceHash;
    bool public whitelistPaused;
    uint256 public minMintPrice;

    uint32 public marketplaceFeeBps;
    uint32 public marketplaceSecondaryFeeBps;
    uint32 public royaltyFeeBps;
    uint32 public creatorFeeBps;

    string private _baseTokenURI;

    mapping(uint256 => AccountInfo) public accounts;
    mapping(uint256 => AccountAddressInfo) public accountAddresses;
    mapping(uint256 => mapping(uint256 => bool)) public locklists;
    mapping(address => bool) public xnftContracts;
    mapping(uint256 => uint256) public mintCount;
    mapping(address => bool) public whitelists;

    mapping(bytes32 => uint256) internal accountNames;
    mapping(uint256 => mapping(address => uint256)) internal userMintCount;
    mapping(bytes32 => bool) internal accountIdsHash;

    event OperatorUpdated(address newOperator);
    event WhitelistPaused(bool status);
    event MinMintPriceUpdated(uint256 minMintPrice);
    event MarketplaceFeeBpsUpdated(uint32 newMarketplaceFeeBps);
    event MarketplaceSecondaryFeeBpsUpdated(
        uint32 newMarketplaceSecondaryFeeBps
    );
    event MarketplaceFeeAddressUpdated(address newMarketplaceFeeAddress);
    event CreatorFeeBpsUpdated(uint32 newCreatorFeeBps);
    event RoyaltyFeeBpsUpdated(uint32 newRoyaltyFeeBps);
    event MarketplaceHashUpdated(bytes4 newMarketplaceHash);

    event WhitelistUpdated(address whitelist, bool status);
    event LocklistUpdated(
        bytes32 accountNameHash,
        uint256 tokenId,
        bool status
    );
    event AccountCreated(
        string accountName,
        address instance,
        uint256 indexed mintTimestamp,
        uint256 indexed revealTimestamp,
        uint32 maxMintCount,
        uint32 maxMintPerWallet,
        uint256 mintPrice
    );

    function __NFTweetsBase_init() internal onlyInitializing {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        accountId = 1;
        // marketplaceFeeBps set to 0
        marketplaceSecondaryFeeBps = 250;
        creatorFeeBps = 1000;
        royaltyFeeBps = 250;
        marketplaceHash = bytes4(keccak256("locksonic.io"));
    }

    // --- Royalties --- //

    /**
     * @dev Retrieves royalty information for a given NFT.
     * @param _accoundId The account ID of the collection.
     * @param _salePrice The sale price of the NFT.
     * @return address The address to receive royalties.
     * @return uint256 The royalty amount to be paid.
     * @notice This function calculates royalties based on the sale price and contract parameters.
     */
    function royaltyInfo(
        uint256 _accoundId,
        uint256 _salePrice
    ) public view returns (address, uint256) {
        address accountFeeAddress = accounts[_accoundId].accountFeeAddress;
        if (accountFeeAddress == address(0)) return (address(0), 0);
        uint256 royaltyAmount = (_salePrice * royaltyFeeBps) / FEE_DENOMINATOR;
        return (accountFeeAddress, royaltyAmount);
    }

    // --- URI --- //
    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Retrieves the contract URI for a given account ID.
     * @param _accountId The ID of the account.
     * @return string The contract URI.
     */
    function contractURI(
        uint256 _accountId
    ) public view virtual returns (string memory) {
        string memory accountNameHash = uint256(
            accounts[_accountId].accountNameHash
        ).toHexString();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        accountNameHash,
                        "/",
                        "metadata",
                        "/",
                        "default"
                    )
                )
                : "";
    }

    /**
     * @dev Retrieves the token URI for a specific token ID associated with an account.
     * @param _accountId The ID of the account associated with the token.
     * @param tokenId The ID of the token.
     * @return string The token URI.
     * @notice This function retrieves the token URI for a specific token ID associated with an account.
     */
    function tokenURI(
        uint256 _accountId,
        uint256 tokenId
    ) public view returns (string memory) {
        AccountInfo memory account = accounts[_accountId];
        string memory accountNameHash = uint256(account.accountNameHash)
            .toHexString();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        accountNameHash,
                        "/",
                        "metadata",
                        "/",
                        account.revealTimestamp.toString(),
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint256[33] __gap;
}
