// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./Auction.sol";

contract BuyNowAuction is MonegraphAuction {
    event AuctionCreated(string metadata);
    event BidReceived(address bidder);

    modifier minimumBid() {
        require(
            msg.value >= initialBidAmount,
            "Incorrect purchase price received"
        );
        _;
    }

    function initialize(
        address payable _beneficiary,
        string memory _metadata,
        uint256 _initialBidAmount
    ) public notZeroAddress(_beneficiary) {
        super.initialize(
            _beneficiary,
            _metadata,
            _initialBidAmount,
            block.timestamp,
            0
        );

        emit AuctionCreated(metadata);
    }

    function bid()
        public
        payable
        override
        auctionHasStarted
        auctionNotClosed
        minimumBid
    {
        beneficiary.transfer(msg.value);

        highestBidder = msg.sender;
        highestBid = msg.value;
        endTime = block.timestamp;
        finalizedTime = block.timestamp;

        bids[msg.sender].push(
            Bid({amount: msg.value, timestamp: block.timestamp})
        );

        emit BidReceived(msg.sender);
    }
}
