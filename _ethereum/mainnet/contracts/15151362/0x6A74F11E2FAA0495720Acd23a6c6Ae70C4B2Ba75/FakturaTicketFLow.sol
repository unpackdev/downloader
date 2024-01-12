// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./ERC721AUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./TreasuryNode.sol";

/**
 * @title Faktura NFTs implemented using the ERC-721A standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FakturaTicketFlow is
TreasuryNode,
ERC721AUpgradeable,
OwnableUpgradeable,
AccessControlUpgradeable,
ERC721ABurnableUpgradeable,
PausableUpgradeable,
UUPSUpgradeable
{
    struct DutchAuction {
        uint256 decreaseInterval; // The number of units to wait before decreasing the price.
        uint256 decreaseSize; // Decrease Size price
        uint256 numDecreases; // The maximum number of price decreases before remaining constant.
    }

    struct Categories {
        string baseURI; // TokenBase URI
        uint256 mintReserve; // Mint Reserve
        bool revealed; // TokenBase Reveal
        uint256 tokenSupply; // gets incremented to placehold for tokens not minted yet
    }

    struct Token {
        uint256 id;
        uint256 category;
    }

    struct Sales {
		uint256 salesType;
        uint256 startDate;
        uint256 endDate;
        uint256 mintPrice;
		uint256 maxPool;
        uint256 maxPerWallet;
        bool hasWhitelist;
        DutchAuction auction;
	}

    address private creatorFakturaAddress;
    uint256 public expectedTokenSupply;

    mapping(uint256 => Sales) private salesPhase;
    mapping(uint256 => Categories) private categories;
    mapping(uint256 => Token) private tokenCategory;

    // ADMIN Role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        string memory name,
        string memory symbol,
        Sales[] memory _salesPhase,
        Categories[] memory _categories,
        uint256 _expectedTokenSupply,
        address payable _fakturaPaymentAddress,
        address payable _creatorPaymentAddress,
        address _creatorFakturaAddress,
        uint256 _secondaryFakturaFeeBasisPoints,
        uint256 _secondaryCreatorFeeBasisPoints
    ) initializerERC721A initializer public {
        __TreasuryNode_init(_fakturaPaymentAddress, _creatorPaymentAddress, _secondaryFakturaFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
        __ERC721A_init(name, symbol);
        __ERC721ABurnable_init();
        __Ownable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _fakturaPaymentAddress);
        _grantRole(ADMIN_ROLE, _creatorPaymentAddress);

        for (uint8 index = 0; index < _salesPhase.length; index++) {
            salesPhase[index] = _salesPhase[index];
        }

        for (uint8 index = 0; index < _categories.length; index++) {
            categories[index] = _categories[index];
        }

        // set the Creator Faktura Address
        creatorFakturaAddress = _creatorFakturaAddress;
        expectedTokenSupply = _expectedTokenSupply;
    }
 
    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Token memory token = tokenCategory[tokenId];
        if(categories[token.category].revealed) {
            return string(abi.encodePacked(categories[token.category].baseURI, _toString(token.id), ".json"));
        } else {
            return string(abi.encodePacked(categories[token.category].baseURI, "unrevealed.json"));
        }
    }

    function tokenIdCounter() public view virtual returns (uint256) {
        return _totalMinted();
    }

    function timestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function getPrice(uint8 n, uint256 sales) public view returns (uint) {
        if(salesPhase[sales].salesType == 2) {
            uint256 decreases = MathUpgradeable.min(
                (block.timestamp - salesPhase[sales].startDate) / salesPhase[sales].auction.decreaseInterval,
                    salesPhase[sales].auction.numDecreases
            );
            return n * (salesPhase[sales].mintPrice - decreases * salesPhase[sales].auction.decreaseSize);
        } else {
            return n * salesPhase[sales].mintPrice;
        }
    }

    function getSalesPhase(uint256 sales) public view returns (Sales memory) {
        return salesPhase[sales];
    }

    function getCategories(uint256 category) public view returns (Categories memory) {
        return categories[category];
    }

    function getMintedByAddress(address to, uint256 sales) public view returns (uint256) {
        return _totalMintedByAddress(to, sales);
    }

    function safeMint(address to, uint8 amount, uint256 sales, uint256 category, bytes32 r, bytes32 s, uint8 v) public payable whenNotPaused {
        require(salesPhase[sales].salesType != 0, "SalesPhase not exist.");
        require(salesPhase[sales].startDate <= block.timestamp, "SalesPhase not started.");
        require(salesPhase[sales].endDate > block.timestamp || salesPhase[sales].endDate == 0, "SalesPhase finished.");
        require(_totalMintedByCategories(category) + amount <= categories[category].tokenSupply - categories[category].mintReserve, "Category soldout.");
        require(_totalMintedBySales(sales) + amount <= salesPhase[sales].maxPool || salesPhase[sales].maxPool == 0, "SalesPhase soldout.");
        require(_totalMintedByAddress(to, sales) + amount <= salesPhase[sales].maxPerWallet, "maxPerWallet limit.");
        require(msg.value >= getPrice(amount, sales), "Mint price is not correct.");
        if(salesPhase[sales].hasWhitelist) {
            bytes32 digest = keccak256(abi.encode(sales, to));
            require(_isVerifiedCoupon(digest, r, s, v), 'Invalid coupon');
        }
        uint256 _currentIndex = ERC721AStorage.layout()._currentIndex;
        uint256 _currentCategoriesIndex = ERC721AStorage.layout()._currentCategoriesIndex[category];
        _safeMint(to, amount, sales, category);
        _setTokenURI(_currentIndex, _currentCategoriesIndex, category);
    }

    /// @dev check that the coupon sent was signed by the admin signer
	function _isVerifiedCoupon(bytes32 digest, bytes32 r, bytes32 s, uint8 v)
		internal
		view
		returns (bool)
	{
		address signer = ecrecover(digest, v, r, s);
		require(signer != address(0), 'ECDSA: invalid signature'); // Added check for zero address
		return signer == creatorFakturaAddress;
	}

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, uint256 _currentCategoriesIndex, uint256 category) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenCategory[tokenId] = Token(_currentCategoriesIndex, category);
    }

    // ** -------------------------------- OVERRIDE ---------------------------------- ** //

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(ADMIN_ROLE)
    override
    {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721AUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(address from,
        address to,
        uint256 startTokenId,
        uint256 quantity)
    internal
    whenNotPaused
    override(ERC721AUpgradeable)
    {
        ERC721AUpgradeable._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function transferOwnership(address newOwner) public virtual override(OwnableUpgradeable) onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    // ** -------------------------------- ADMIN ---------------------------------- ** //

    function withdraw() external onlyRole(ADMIN_ROLE) {
        (uint256 secondaryFakturaFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = getFeeConfig();
        uint256 balance = address(this).balance;
        //Pay to Treasury
        payable(getTreasury()).transfer((balance * secondaryFakturaFeeBasisPoints) / 100);
        //Pay to Creator
        payable(getCreatorPaymentAddress()).transfer((balance * secondaryCreatorFeeBasisPoints) / 100);
    }

    function reveal(string memory uri, uint256 category) public onlyRole(ADMIN_ROLE) {
        require(categories[category].revealed == false, "Already revealed.");
        categories[category].baseURI = uri;
        categories[category].revealed = true;
    }

    function safeReserveMint(address to, uint256 amount, uint256 sales, uint256 category) public onlyRole(ADMIN_ROLE) {
        require(_totalMintedByCategories(category) + amount < categories[category].tokenSupply, "There's no token to mint.");
        uint256 _currentIndex = ERC721AStorage.layout()._currentIndex;
        uint256 _currentCategoriesIndex = ERC721AStorage.layout()._currentCategoriesIndex[category];
        _safeMint(to, amount, sales, category);
        _setTokenURI(_currentIndex, _currentCategoriesIndex, category);
    }

    function setReserve(uint256 _mintReserve, uint256 category) public onlyRole(ADMIN_ROLE) {
        categories[category].mintReserve = _mintReserve;
    }

    function setSalesPhase(Sales memory _salesPhase, uint8 position) public onlyRole(ADMIN_ROLE) {
        salesPhase[position] = _salesPhase;
    }

    function setCategory(Categories memory _category, uint8 position) public onlyRole(ADMIN_ROLE) {
        categories[position] = _category;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function changeCreatorPaymentAddress(address payable _to) public onlyRole(ADMIN_ROLE) {
        require(getCreatorPaymentAddress() == msg.sender, "Only the creator can change his account.");
        _grantRole(ADMIN_ROLE, _to);
        setCreatorPaymentAddress(_to);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}