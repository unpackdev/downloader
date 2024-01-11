// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./ERC721AUpgradeable.sol";
import "./ERC721ABurnableUpgradeable.sol";

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
    // gets incremented to placehold for tokens not minted yet
    uint256 public expectedTokenSupply;
    // Mint Reserve
    uint256 public mintReserve;
    // TokenBase URI
    string private tokenBaseURI;
    // TokenBase Reveal
    bool public revealed;

    address private creatorFakturaAddress;

    mapping(uint256 => Sales) private salesPhase;
    // ADMIN Role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(
        string memory name,
        string memory symbol,
        string memory _tokenBaseURI,
        Sales[] memory _salesPhase,
        uint256 _mintReserve,
        bool _revealed,
        uint256 _tokenSupply,
        address payable _fakturaPaymentAddress,
        address payable _creatorPaymentAddress,
        address _creatorFakturaAddress,
        uint256 _secondaryFakturaFeeBasisPoints,
        uint256 _secondaryCreatorFeeBasisPoints
    ) initializerERC721A initializer public {
        __TreasuryNode_init(_fakturaPaymentAddress, _creatorPaymentAddress, _secondaryFakturaFeeBasisPoints, _secondaryCreatorFeeBasisPoints);
        __ERC721A_init(name, symbol);
        __ERC721ABurnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, _fakturaPaymentAddress);
        _grantRole(ADMIN_ROLE, _creatorPaymentAddress);

        for (uint8 index = 0; index < _salesPhase.length; index++) {
            salesPhase[index] = _salesPhase[index];
        }
        // set the revealed bool
        revealed = _revealed;
        // set tokenBaseURI if revealed isnt true
        tokenBaseURI = _tokenBaseURI;
        // set the reserve
        mintReserve = _mintReserve;
        // set the initial expected token supply
        expectedTokenSupply = _tokenSupply;
        // set the Creator Faktura Address
        creatorFakturaAddress = _creatorFakturaAddress;

        require(expectedTokenSupply > 0,
            "TokenSupply: should be higher"
        );
    }
 
    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed) {
            return string(abi.encodePacked(tokenBaseURI, _toString(tokenId), ".json"));
        } else {
            return string(abi.encodePacked(tokenBaseURI, "unrevealed.json"));
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

    function getSales(uint256 sales) public view returns (Sales memory) {
        return salesPhase[sales];
    }

    function getMintedByAddress(address to, uint256 sales) public view returns (uint256) {
        return _totalMintedByAddress(to, sales);
    }

    function safeMint(address to, uint8 amount, uint256 sales, bytes32 r, bytes32 s, uint8 v) public payable whenNotPaused {
        require(salesPhase[sales].salesType != 0, "SalesPhase not exist.");
        require(salesPhase[sales].startDate <= block.timestamp, "SalesPhase not started.");
        require(salesPhase[sales].endDate > block.timestamp || salesPhase[sales].endDate == 0, "SalesPhase finished.");
        require(_totalMinted() + amount <= expectedTokenSupply - mintReserve, "Collection soldout.");
        require(_totalMintedBySales(sales) + amount <= salesPhase[sales].maxPool || salesPhase[sales].maxPool == 0, "SalesPhase soldout.");
        require(_totalMintedByAddress(to, sales) + amount <= salesPhase[sales].maxPerWallet, "maxPerWallet limit.");
        require(msg.value >= getPrice(amount, sales), "Mint price is not correct.");
        if(salesPhase[sales].hasWhitelist) {
            bytes32 digest = keccak256(abi.encode(sales, to));
            require(_isVerifiedCoupon(digest, r, s, v), 'Invalid coupon');
        }

        _safeMint(to, amount, sales);
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
     * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
     */
    function _burn(uint256 tokenId) internal override(ERC721AUpgradeable) {
        super._burn(tokenId);
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

    // ** -------------------------------- ADMIN ---------------------------------- ** //

    function withdraw() external onlyRole(ADMIN_ROLE) {
        (uint256 secondaryFakturaFeeBasisPoints, uint256 secondaryCreatorFeeBasisPoints) = getFeeConfig();
        uint256 balance = address(this).balance;
        //Pay to Treasury
        payable(getTreasury()).transfer((balance * secondaryFakturaFeeBasisPoints) / 100);
        //Pay to Creator
        payable(getCreatorPaymentAddress()).transfer((balance * secondaryCreatorFeeBasisPoints) / 100);
    }

    function reveal(string memory uri) public onlyRole(ADMIN_ROLE) {
        require(revealed == false, "Already revealed.");
        tokenBaseURI = uri;
        revealed = true;
    }

    function safeReserveMint(address to, uint256 amount, uint256 sales) public onlyRole(ADMIN_ROLE) {
        require(_totalMinted() + amount < expectedTokenSupply, "There's no token to mint.");
        _safeMint(to, amount, sales);
    }

    function setReserve(uint256 _mintReserve) public onlyRole(ADMIN_ROLE) {
        mintReserve = _mintReserve;
    }

    function setSalesPhase(Sales memory _salesPhase, uint8 position) public onlyRole(ADMIN_ROLE) {
        salesPhase[position] = _salesPhase;
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