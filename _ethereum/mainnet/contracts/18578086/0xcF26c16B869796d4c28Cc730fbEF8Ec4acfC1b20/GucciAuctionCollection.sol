// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableRoles.sol";
import "./ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./GucciAuctionStorage.sol";

contract GucciAuctionCollection is
    OwnableRoles,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    event AuctionCreated(uint256 indexed auctionId, address indexed creator);
    event AuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionActive(uint256 indexed auctionId, bool indexed active);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 amount);

    modifier hasAuction(uint256 auctionId) {
        require(GucciAuctionStorage.layout()._auctions[auctionId].creator != address(0), "Auction doesn't exist");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address royalty_,
        uint96 royaltyFee_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        _initializeOwner(owner_);
        __ERC721_init(name_, symbol_);
        __ERC2981_init();

        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function createAuction(uint256 auctionId, Auction calldata auction)
        external
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        require(auction.creator != address(0), "Creator must exist");
        require(auction.duration >= auction.timeBuffer, "Duration too short");

        GucciAuctionStorage.layout()._auctions[auctionId] = auction;

        emit AuctionCreated(auctionId, auction.creator);
    }

    function setAuction(uint256 auctionId, Auction calldata auction)
        external
        hasAuction(auctionId)
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        require(auction.creator != address(0), "Creator must exist");
        require(auction.duration >= auction.timeBuffer, "Duration too short");

        GucciAuctionStorage.layout()._auctions[auctionId] = auction;
    }

    function placeBid(uint256 auctionId) external payable hasAuction(auctionId) nonReentrant {
        Auction storage auction = GucciAuctionStorage.layout()._auctions[auctionId];

        require(auction.active, "Auction not active");
        require(msg.value > 0, "Has no value");
        require(msg.value >= auction.reservePrice, "Lower than reserve price");
        require(auction.startedAt == 0 || block.timestamp < auction.startedAt + auction.duration, "Auction expired");
        require(
            msg.value >= auction.amount + ((auction.amount * auction.minBidNumerator) / 10000),
            "Lower than minimum bid amount"
        );

        // Return the previous bid if there is any
        if (auction.bidder != address(0)) {
            AddressUpgradeable.sendValue(payable(address(auction.bidder)), auction.amount);
        }

        // Extend duration if bid was placed below the time buffer
        if ((auction.startedAt + auction.duration - block.timestamp) < auction.timeBuffer) {
            uint256 prevDuration = auction.duration;
            auction.duration =
                prevDuration + (auction.timeBuffer - (auction.startedAt + prevDuration - block.timestamp));
        }

        auction.amount = msg.value;
        auction.bidder = _msgSender();

        emit AuctionBidPlaced(auctionId, _msgSender(), msg.value);
    }

    function endAuction(uint256 auctionId) external payable hasAuction(auctionId) nonReentrant {
        Auction storage auction = GucciAuctionStorage.layout()._auctions[auctionId];

        require(auction.active, "Auction not active");
        require(auction.startedAt != 0, "Auction hasn't started");
        require(block.timestamp >= auction.startedAt + auction.duration, "Auction hasn't completed");

        _safeMint(auction.bidder, auctionId);
        _setTokenURI(auctionId, auction.tokenURI);
        _setTokenRoyalty(auctionId, auction.creator, auction.royaltyNumerator);

        AddressUpgradeable.sendValue(payable(auction.creator), auction.amount);

        emit AuctionEnded(auctionId, auction.bidder, auction.amount);
    }

    function setAuctionsActive(uint256[] calldata auctionIds, bool active)
        external
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        uint256 length = auctionIds.length;
        for (uint256 i = 0; i < length; i++) {
            setAuctionActive(auctionIds[i], active);
        }
    }

    function setAuctionActive(uint256 auctionId, bool active)
        public
        hasAuction(auctionId)
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        Auction storage auction = GucciAuctionStorage.layout()._auctions[auctionId];

        auction.active = active;
        auction.startedAt = active ? block.timestamp : 0;

        emit AuctionActive(auctionId, active);
    }

    function cancelAuction(uint256 auctionId)
        external
        hasAuction(auctionId)
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        Auction storage auction = GucciAuctionStorage.layout()._auctions[auctionId];
        require(auction.bidder != address(0), "Has no bidder");

        auction.amount = 0;
        auction.bidder = address(0);
        auction.startedAt = 0;
        auction.active = false;

        AddressUpgradeable.sendValue(payable(auction.bidder), auction.amount);
    }

    function getAuction(uint256 auctionId) external view hasAuction(auctionId) returns (Auction memory) {
        return GucciAuctionStorage.layout()._auctions[auctionId];
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        external
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setTokenURI(uint256 tokenId, string calldata tokenURI_)
        external
        onlyOwnerOrRoles(GucciAuctionStorage.ADMIN_ROLE)
    {
        _setTokenURI(tokenId, tokenURI_);
    }

    // The following functions are overrides required by Solidity.
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        ERC721Upgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId)
            || ERC721URIStorageUpgradeable.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }
}
