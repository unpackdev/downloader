// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct Auction {
    // Token URI for auction
    string tokenURI;
    // Address that should receive the funds
    address creator;
    // Reserve price
    uint256 reservePrice;
    // The length of time to run the auction for
    uint256 duration;
    // Current highest bid amount
    uint256 amount;
    // Address of the highest bidder
    address bidder;
    // Minimum time buffer after a new bid is placed
    uint256 timeBuffer;
    // Minimum percentage bid amount
    uint96 minBidNumerator;
    // Base royalty percentage
    uint96 royaltyNumerator;
    // Auction is active
    bool active;
    // Auction started time
    uint256 startedAt;
}

library GucciAuctionStorage {
    bytes32 private constant STORAGE_SLOT = keccak256("niftykit.gucci.auction");

    uint256 public constant ADMIN_ROLE = 1 << 0;

    struct Layout {
        mapping(uint256 => Auction) _auctions;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}
