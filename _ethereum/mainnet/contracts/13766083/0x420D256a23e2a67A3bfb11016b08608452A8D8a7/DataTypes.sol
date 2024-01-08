// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;


library DataTypes {
    struct AuctionData {
        uint256 currentBid;
        address bidToken; // determines currentBid token, zero address means ether
        address auctioneer;
        address currentBidder;
        uint256 endTimestamp;
    }
}
