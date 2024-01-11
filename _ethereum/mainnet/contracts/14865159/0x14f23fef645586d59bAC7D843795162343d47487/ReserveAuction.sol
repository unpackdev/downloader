pragma solidity 0.8.12;

import "./IERC721.sol";
import "./ExchangeCore.sol";

abstract contract ReserveAuction is ExchangeCore {
    uint32 constant AUCTION_DURATION = 24 hours;
    uint16 constant MINIMUM_BID_END_AUCTION_BUFFER = 15 minutes;
    uint8 constant MINIMUM_BID_INCREASE_PERCENTAGE = 5;

    struct Auction {
        address seller;
        uint256 startPrice;
        address maxBidder;
        uint256 maxBid;
        uint256 startsAt;
        uint128 endsAt;
    }

    mapping(address => mapping(uint256 => Auction)) public auctions;

    event ReserveAuctionCreated(
        address creator,
        address indexed collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    );

    event ReserveAuctionBid(
        address bidder,
        address indexed collection,
        uint256 tokenId,
        uint256 startedAt,
        uint256 bidValue,
        uint256 endsAt
    );

    event ReserveAuctionClaimed(
        address seller,
        address maxBidder,
        address indexed collection,
        uint256 tokenId,
        uint256 startedAt,
        uint256 endedAt,
        uint256 maxBid
    );

    event ReserveAuctionCanceled(
        address seller,
        address indexed collection,
        uint256 tokenId,
        uint256 startedAt
    );

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (startsAt < block.timestamp)
            revert Exchange_Starts_At_Must_Be_In_Future();
        if (startsAt - block.timestamp > 15 days)
            revert Exchange_Starts_At_Too_Far();

        _createReserveAuction(collection, tokenId, startPrice, startsAt);
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        _createReserveAuction(collection, tokenId, startPrice, block.timestamp);
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        address royaltyReceiver,
        uint256 royaltyPercentage,
        uint256 startPrice,
        uint256 startsAt
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        if (startsAt < block.timestamp)
            revert Exchange_Starts_At_Must_Be_In_Future();
        if (startsAt - block.timestamp > 15 days)
            revert Exchange_Starts_At_Too_Far();

        _createReserveAuction(collection, tokenId, startPrice, startsAt);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );
    }

    function createReserveAuction(
        address collection,
        uint256 tokenId,
        address royaltyReceiver,
        uint256 royaltyPercentage,
        uint256 startPrice
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        _createReserveAuction(collection, tokenId, startPrice, block.timestamp);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );
    }

    function bid(address collection, uint256 tokenId)
        external
        payable
        nonReentrant
        onlyNonBlacklistedUsers
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        Auction memory auction = auctions[collection][tokenId];

        if (block.timestamp < auction.startsAt)
            revert Exchange_Drop_Not_Started_Yet();

        // FLOW 01:: Auction did't start yet, and this is the first bid
        // Execute the bellow block and return
        if (auction.endsAt == 0) {
            if (msg.value < auction.startPrice)
                revert Exchange_Invalid_Start_Price(
                    auction.startPrice,
                    msg.value
                );
            auctions[collection][tokenId].endsAt =
                uint128(block.timestamp) +
                AUCTION_DURATION;

            auctions[collection][tokenId].maxBidder = msg.sender;
            auctions[collection][tokenId].maxBid = msg.value;

            emit ReserveAuctionBid(
                msg.sender,
                collection,
                tokenId,
                auction.startsAt,
                msg.value,
                auctions[collection][tokenId].endsAt
            );
            return;
        }

        // FLOW 02:: Auction already started but expired
        // (FLOW 01) is ignored
        if (block.timestamp > auction.endsAt) {
            revert Exchange_Rejected_Ended_Auction(
                auction.endsAt,
                block.timestamp
            );
        }

        // FLOW 03:: Auction already started and not expired
        // (FLOW 01) and (FLOW 02) are ignored
        // Extend if it Will expire in less than 15 minutes
        uint128 fifteenMinutesLater = uint128(block.timestamp) +
            MINIMUM_BID_END_AUCTION_BUFFER;
        if (fifteenMinutesLater > auction.endsAt) {
            auctions[collection][tokenId].endsAt = fifteenMinutesLater;
        }

        // Revert if value is not 5% higher than previous bid
        uint256 minimumNextBid = auction.maxBid +
            ((auction.maxBid * MINIMUM_BID_INCREASE_PERCENTAGE) / 100);
        if (msg.value < minimumNextBid)
            revert Exchange_Rejected_Must_Be_5_Percent_Higher(
                minimumNextBid,
                msg.value
            );

        auctions[collection][tokenId].maxBidder = msg.sender;
        auctions[collection][tokenId].maxBid = msg.value;

        // Refund previous bidder, send eth with fallback
        ExchangeCore._sendEthWithFallback(auction.maxBidder, auction.maxBid);

        emit ReserveAuctionBid(
            msg.sender,
            collection,
            tokenId,
            auction.startsAt,
            msg.value,
            auctions[collection][tokenId].endsAt
        );
    }

    function cancelAuction(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (auctions[collection][tokenId].seller != msg.sender)
            revert Exchange_Rejected_Not_Auction_Owner();

        if (auctions[collection][tokenId].endsAt != 0)
            revert Exchange_Rejected_Auction_In_Progress();

        uint256 startedAt = auctions[collection][tokenId].startsAt;

        delete auctions[collection][tokenId];

        IERC721(collection).transferFrom(address(this), msg.sender, tokenId);

        emit ReserveAuctionCanceled(msg.sender, collection, tokenId, startedAt);
    }

    function claimAuction(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        Auction memory auction = auctions[collection][tokenId];
        delete auctions[collection][tokenId];

        // Auction not found
        if (auction.seller == address(0) || auction.maxBidder == address(0))
            revert Exchange_Auction_Not_Found();

        // Auction didn't start yet
        if (auction.endsAt == 0)
            revert Exchange_Rejected_Auction_Not_Started_Yet();

        // Auction still in progress
        if (block.timestamp < auction.endsAt)
            revert Exchange_Rejected_Auction_In_Progress();

        ExchangeCore._executeETHPaymentWithFallback(
            collection,
            tokenId,
            auction.seller,
            auction.maxBid
        );

        IERC721(collection).transferFrom(
            address(this),
            auction.maxBidder,
            tokenId
        );

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                auction.maxBidder,
                auction.seller,
                auction.maxBid,
                collection,
                tokenId
            );
        }

        emit ReserveAuctionClaimed(
            auction.seller,
            auction.maxBidder,
            collection,
            tokenId,
            auction.startsAt,
            auction.endsAt,
            auction.maxBid
        );
    }

    function _createReserveAuction(
        address collection,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startsAt
    ) private {
        if (startPrice == 0) revert Exchange_Invalid_Nullish_Price();
        if (collection == address(0)) revert RejectedNullishAddress();

        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        auctions[collection][tokenId] = Auction({
            seller: msg.sender,
            startPrice: startPrice,
            maxBidder: address(0),
            maxBid: 0,
            startsAt: startsAt,
            endsAt: 0
        });

        emit ReserveAuctionCreated(
            msg.sender,
            collection,
            tokenId,
            startPrice,
            startsAt
        );
    }
}
