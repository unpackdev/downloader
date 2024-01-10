//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";

contract GoldFeverMarket is IERC721Receiver, ERC721Holder, ReentrancyGuard {
    bytes32 public constant STATUS_CREATED = keccak256("STATUS_CREATED");
    bytes32 public constant STATUS_SOLD = keccak256("STATUS_SOLD");
    bytes32 public constant STATUS_CANCELED = keccak256("STATUS_CANCELED");

    uint256 public constant build = 3;

    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    IERC20 ngl;

    constructor(address ngl_) public {
        ngl = IERC20(ngl_);
    }

    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bytes32 status;
    }

    mapping(uint256 => Listing) public idToListing;

    event ListingCreated(
        uint256 indexed listingId,
        address nftContract,
        uint256 tokenId,
        address seller,
        uint256 price
    );
    event ListingCanceled(uint256 indexed listingId);
    event ListingSold(uint256 indexed listingId, address indexed buyer);

    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        idToListing[listingId] = Listing(
            listingId,
            nftContract,
            tokenId,
            msg.sender,
            price,
            STATUS_CREATED
        );

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ListingCreated(listingId, nftContract, tokenId, msg.sender, price);
    }

    function cancelListing(uint256 listingId) public nonReentrant {
        require(idToListing[listingId].seller == msg.sender, "Not seller");
        require(
            idToListing[listingId].status == STATUS_CREATED,
            "Item is not for sale"
        );
        address seller = idToListing[listingId].seller;
        uint256 tokenId = idToListing[listingId].tokenId;
        address nftContract = idToListing[listingId].nftContract;
        IERC721(nftContract).safeTransferFrom(address(this), seller, tokenId);
        idToListing[listingId].status = STATUS_CANCELED;
        emit ListingCanceled(listingId);
    }

    function buyListing(uint256 listingId) public nonReentrant {
        require(
            idToListing[listingId].status == STATUS_CREATED,
            "Item is not for sale"
        );
        uint256 price = idToListing[listingId].price;
        address seller = idToListing[listingId].seller;
        uint256 tokenId = idToListing[listingId].tokenId;
        address nftContract = idToListing[listingId].nftContract;

        ngl.transferFrom(msg.sender, seller, price);
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        idToListing[listingId].status = STATUS_SOLD;
        emit ListingSold(listingId, msg.sender);
    }
}
