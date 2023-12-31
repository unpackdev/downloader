// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

enum AuctionType {
    TimedAuction,
    FixedPrice,
    TimedAndFixed
}

enum AuctionStatus {
    Open,
    Closed
}

struct Bid {
    uint128 bidAmount;
    uint128 bidPrice;
    address bidder;
    // bid token amount paid out when bidding
    uint128 paidAmount;
    uint16 bidTokenId;
    bool bCleared;
}

struct BidTokenGroup {
    // tokens in one group should be max 255
    address[] bidTokens;
    // calculated price by this address
    address basePriceToken;
    bytes32 name;
}

struct AuctionSetting {
    // start and expired time
    uint48 startTime;
    uint48 endTime;
    // listed token address
    address sellToken;
    // tranche id for tranche nft auction
    uint256 trancheIndex;
    // minimum bid or buy amount
    uint128 minBidAmount;
    // fixed price used when buying directly, without bidding
    uint128 fixedPrice;
    // lowest and highest bid price
    uint128 priceRangeStart;
    uint128 priceRangeEnd;
    // total amount of listed token
    uint128 sellAmount;
    // while auction is open, available token amount
    uint128 reserve;
    // price used when bidding in increment way
    uint128 incrementBidPrice;
    // bid token group id
    uint16 bidTokenGroupId;
    // auction type
    AuctionType auctionType;
}
/// @dev Contains all data for erc20 or tranche auction
struct AuctionData {
    // config params set by autioneer
    AuctionSetting s;
    // current bid id
    uint128 curBidId;
    // total amount of bids that can win after auction is closed
    uint128 totalBidAmount;
    // seller address
    address seller;
    // number of bids that can win after auction is closed. all bids out the range of availableBidDepth are canceled when bidding.
    uint8 availableBidDepth;
    // auction status
    AuctionStatus status;
    // fee amount used for refunded fee calculation
    uint256 feeAmount;
}

library AuctionStorage {
    struct Layout {
        // count of auctions and current auction id
        uint256 currentAuctionId;
        // all auctions by auction id
        mapping(uint256 => AuctionData) auctions;
        // all bids by auction id and bid id
        mapping(uint256 => mapping(uint256 => Bid)) bids;
        // whitelist for sell tokens
        mapping(address => bool) supportedSellTokens;
        // bid token groups
        mapping(uint256 => BidTokenGroup) bidTokenGroups;
        // count of bid token groups
        uint256 countOfTokenGroups;
        // fee amount and fee receiver address        
        uint256 feeNumerator;
        address feeReceiver;
        // deprecated
        uint96 maxIncrementRate;
        // available auction periods like 1 day, 3 days,
        uint48[] periods;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.Auction");

    function layout() internal pure returns (Layout storage ls) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            ls.slot := slot
        }
    }
}
