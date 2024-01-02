// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./FeeControllerI.sol";
import "./Ownable.sol";
import "./SafeI.sol";
import "./MembershipNftV1.sol";

interface MembershipNftV2I is MembershipNftV1I {
    struct TokenEdition {
        // The maximum number of tokens that can be sold. 0 for open edition.
        uint256 tokenId;
        // block.timestamp when the sale end. 0 for no ending time.
        uint256 editionId;
        // current owner of this token
        address owner;
        // block.timestamp when the sale starts. 0 for immediate mint availability.
        uint256 serialNumber;
        // The voting power to be used by another smart contract interactions
        uint256 votingPower;
    }

    function getTokenById(uint256 tokenId) external view returns (TokenEdition memory);

    function getTokenByIndex(uint256 index) external view returns (TokenEdition memory);

    function version() external pure returns (string memory);
}

/// @notice Implementation for Crowdfund NFT owned by a safe
contract MembershipNftV2 is MembershipNftV2I, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable {
    using StringsUpgradeable for uint256;

    error EditionSaleNotStarted();
    error EditionSaleEnded();
    error EditionNotExist();
    error TokenNotExist();
    error EditionSoldOut();
    error UnauthorizedAccount(address account);
    error RoyaltyBpExceedsMax();

    event EditionCreated(
        uint256 indexed editionId,
        uint256 quantity,
        uint256 price,
        uint256 votingPower,
        uint opensAt,
        uint closedAt,
        bytes32 allowlistRoot
    );

    event EditionUpdated(
        uint256 indexed editionId,
        uint256 quantity,
        uint256 price,
        uint256 votingPower,
        uint opensAt,
        uint closedAt,
        bytes32 allowlistRoot
    );

    event EditionPurchased(
        uint256 indexed editionId,
        uint256 indexed tokenId,
    // `numSold` at time of purchase represents the "serial number" of the NFT.
        uint256 numSold,
    // The account that paid for and received the NFT.
        address minter,
        address receiver
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // The account that can update opensea branding
    address private _ownerAddress;
    uint256 private nextTokenId;
    string private _baseUrl;
    mapping(uint256 => Edition) private editions;
    mapping(uint256 => uint256) private tokenIdToSerialNumber;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice the vault that owns this contract. Signers of this vault can create editions.
    SafeI public vault;
    /// @notice Royalty out of 10000
    uint256 public royaltyBp;
    mapping(uint256 => uint256) public tokenToEdition;
    uint256 public nextEditionId;
    // The contract that is able to mint.
    mapping(uint256 => address) public editionToMinter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function init(
        address _owner,
        address _vault,
        string memory name,
        string memory symbol,
        string memory baseUrlIn
    )
    onlyInitializing
    private
    {
        __ERC721_init(name, symbol);
        __ERC721Burnable_init();
        _ownerAddress = _owner;
        // Editions start at 1
        nextEditionId = 1;
        // Tokens start at 1
        nextTokenId = 1;
        // default royalty is 5%
        royaltyBp = 500;
        _baseUrl = baseUrlIn;
        vault = SafeI(_vault);
    }

    function initialize(
        address _owner,
        address _vault,
        string memory name,
        string memory symbol,
        string memory baseUrlIn
    )
    initializer
    public
    {
        init(_owner, _vault, name, symbol, baseUrlIn);
    }

    function initializeEditions(
        address _owner,
        address _vault,
        string memory name,
        string memory symbol,
        string memory baseUrlIn,
        EditionTier[] memory tiers,
        address _minter
    )
    initializer
    public
    {
        init(_owner, _vault, name, symbol, baseUrlIn);
        _createEditions(tiers, _minter);
    }

    function version() external pure override returns (string memory){
        return "2";
    }

    function owner() public view virtual returns (address) {
        return _ownerAddress;
    }

    /// @notice transfer the ownership of this contract to a new address. Does not update vault.
    function transferOwnership(address newOwner) public {
        if (msg.sender != _ownerAddress) {
            revert UnauthorizedAccount(msg.sender);
        }
        address oldOwner = _ownerAddress;
        _ownerAddress = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @dev Throws if called by any account other than the vault.
    modifier onlyVaultOwner() {
        if (!vault.isOwner(msg.sender)) {
            revert UnauthorizedAccount(msg.sender);
        }
        _;
    }

    /// @notice Create one or more editions.
    function createEditions(
        EditionTier[] memory tiers,
        address minter
    )
    public
    onlyVaultOwner
    {
        _createEditions(tiers, minter);
    }

    function _createEditions(
        EditionTier[] memory tiers,
        address minter
    )
    internal
    {
        uint256 firstEditionId = nextEditionId;
        nextEditionId += tiers.length;
        if (minter == address(0)) {
            revert UnauthorizedAccount(minter);
        }

        for (uint8 x = 0; x < tiers.length; x++) {
            uint256 id = firstEditionId + x;
            uint256 quantity = tiers[x].quantity;
            uint256 price = tiers[x].price;
            uint256 votingPower = tiers[x].votingPower;
            uint closedAt = tiers[x].closedAt;
            uint opensAt = tiers[x].opensAt;
            bytes32 allowlistRoot = tiers[x].allowlistRoot;

            editions[id] = Edition({
                quantity: quantity,
                price: price,
                votingPower: votingPower,
                closedAt: closedAt,
                opensAt: opensAt,
                numSold: 0,
                allowlistRoot: allowlistRoot
            });

            editionToMinter[id] = minter;

            emit EditionCreated(
                id,
                quantity,
                price,
                votingPower,
                opensAt,
                closedAt,
                allowlistRoot
            );
        }
    }

    function editionExists(uint256 editionId) internal view {
        if (editionId == 0 || editionId >= nextEditionId) {
            revert EditionNotExist();
        }
    }

    /// @notice Update one or more editions.
    function createAndUpdateEditions(
        EditionTier[] memory tiersToCreate,
        uint256[] memory editionIds,
        EditionTier[] memory tiersToUpdate,
        address minter
    )
    public
    onlyVaultOwner
    {
        if (minter == address(0)) {
            revert UnauthorizedAccount(minter);
        }

        if (tiersToCreate.length > 0) {
            _createEditions(tiersToCreate, minter);
        }

        for (uint8 x = 0; x < editionIds.length; x++) {
            editionExists(editionIds[x]);
        }

        for (uint8 x = 0; x < tiersToUpdate.length; x++) {
            editions[editionIds[x]].price = tiersToUpdate[x].price;
            editions[editionIds[x]].votingPower = tiersToUpdate[x].votingPower;
            editions[editionIds[x]].quantity = tiersToUpdate[x].quantity;
            editions[editionIds[x]].closedAt = tiersToUpdate[x].closedAt;
            editions[editionIds[x]].opensAt = tiersToUpdate[x].opensAt;
            editions[editionIds[x]].allowlistRoot = tiersToUpdate[x].allowlistRoot;
            emit EditionUpdated(
                editionIds[x],
                tiersToUpdate[x].quantity,
                tiersToUpdate[x].price,
                tiersToUpdate[x].votingPower,
                tiersToUpdate[x].opensAt,
                tiersToUpdate[x].closedAt,
                editions[editionIds[x]].allowlistRoot
            );
        }
    }

    /// @notice Mint one or more tokens from an edition.
    function buyEdition(uint256 editionId, address recipient, uint256 amount)
    external
    override
    returns (uint256 firstTokenId)
    {
        // Only the minter can call this function.
        if (msg.sender != editionToMinter[editionId]) {
            revert UnauthorizedAccount(msg.sender);
        }
        if (editionId == 0) {
            revert EditionNotExist();
        }
        if (editions[editionId].opensAt > 0 && editions[editionId].opensAt > block.timestamp) {
            revert EditionSaleNotStarted();
        }
        if (editions[editionId].closedAt > 0 && editions[editionId].closedAt < block.timestamp) {
            revert EditionSaleEnded();
        }
        // Check that there are still tokens available to purchase (for non-open edition).
        if (editions[editionId].quantity != 0 && editions[editionId].numSold + amount > editions[editionId].quantity) {
            revert EditionSoldOut();
        }

        // Track and update token id.
        firstTokenId = nextTokenId;
        for (uint8 x = 0; x < amount; x++) {
            uint256 tokenId = firstTokenId + x;
            uint256 serialNumber = editions[editionId].numSold + x + 1;
            // Mint a new token for the sender, using the `tokenId`.
            _safeMint(recipient, tokenId);
            // Store the mapping of token id to the edition being purchased.
            tokenToEdition[tokenId] = editionId;
            tokenIdToSerialNumber[tokenId] = serialNumber;

            emit EditionPurchased(
                editionId,
                tokenId,
                serialNumber,
                msg.sender,
                recipient
            );

            tokenId++;
        }
        // Increment the number of tokens sold for this edition.
        editions[editionId].numSold += amount;
        nextTokenId += amount;

        return firstTokenId;
    }

    /// @notice Get edition info about an edition
    function getEdition(uint256 editionId) external view returns (Edition memory){
        editionExists(editionId);
        return editions[editionId];
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ){
        _requireMinted(_tokenId);
        uint256 royalty = _salePrice * royaltyBp / 10000;
        return (address(vault), royalty);
    }

    function setRoyaltyBp(uint256 _royaltyBp) external onlyVaultOwner {
        if (_royaltyBp > 10000) {
            revert RoyaltyBpExceedsMax();
        }
        royaltyBp = _royaltyBp;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUrl;
    }

    /// @notice get the token metadata url for a minted token id
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        string memory ownerString = StringsUpgradeable.toHexString(uint160(ownerOf(tokenId)), 20);
        string memory vaultString = StringsUpgradeable.toHexString(uint160(address(vault)), 20);
        string memory collectionAddressString = StringsUpgradeable.toHexString(uint160(address(this)), 20);
        string memory editionId = tokenToEdition[tokenId].toString();
        string memory serialNumber = tokenIdToSerialNumber[tokenId].toString();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(
            baseURI,
            block.chainid.toString(),
            "/",
            collectionAddressString,
            "/",
            tokenId.toString(),
            "?vault=", vaultString, "&owner=", ownerString, "&edition=", editionId, "&serialNumber=", serialNumber
        )) : "";
    }

    /// @notice get the contract metadata url
    function contractURI() external view returns (string memory){
        string memory baseURI = _baseURI();
        string memory vaultString = StringsUpgradeable.toHexString(uint160(address(vault)), 20);
        string memory collectionAddressString = StringsUpgradeable.toHexString(uint160(address(this)), 20);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(
            baseURI,
            block.chainid.toString(),
            "/",
            collectionAddressString,
            "?vault=", vaultString
        )) : "";
    }

    function allTokens() external view returns (TokenEdition[] memory) {
        TokenEdition[] memory tokens = new TokenEdition[](totalSupply());
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokenByIndex(i);
            uint256 editionId =  tokenToEdition[tokenId];
            tokens[i] = TokenEdition({
                tokenId: tokenId,
                editionId: editionId,
                owner: ownerOf(tokenId),
                serialNumber: tokenIdToSerialNumber[tokenId],
                votingPower: editions[editionId].votingPower
            });
        }
        return tokens;
    }

    function getTokenById(uint256 tokenId) public view returns (TokenEdition memory) {
            uint256 editionId =  tokenToEdition[tokenId];
            return TokenEdition({
                tokenId: tokenId,
                editionId: editionId,
                owner: ownerOf(tokenId),
                serialNumber: tokenIdToSerialNumber[tokenId],
                votingPower: editions[editionId].votingPower
            });
    }

    function getTokenByIndex(uint256 index) external view returns (TokenEdition memory) {
        uint256 tokenId = tokenByIndex(index);
        return getTokenById(tokenId);
    }
}