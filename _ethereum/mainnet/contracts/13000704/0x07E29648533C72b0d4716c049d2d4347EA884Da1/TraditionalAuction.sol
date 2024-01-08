// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./Auction.sol";

contract TraditionalAuction is MonegraphAuction {
    event AuctionCreated(string metadata);

    event BidReceived(address bidder);
    event AuctionFinalized(address from);

    uint256 public constant maximumIncrease = 100000000000000000 wei;

    function initialize(
        address payable _beneficiary,
        string memory _metadata,
        uint256 _initialBidAmount,
        uint256 _startTime,
        uint256 _endTime
    ) public override notZeroAddress(_beneficiary) {
        super.initialize(
            _beneficiary,
            _metadata,
            _initialBidAmount,
            _startTime,
            _endTime
        );

        emit AuctionCreated(metadata);
    }

    modifier minimumBid() {
        uint256 minimum = initialBidAmount;

        if (highestBid > 0) {
            uint256 percentIncrease = (highestBid * 10) / 100;
            minimum = percentIncrease > maximumIncrease
                ? highestBid + maximumIncrease
                : highestBid + percentIncrease;
        }

        require(msg.value >= minimum, "Incorrect purchase price received");
        _;
    }

    function bid()
        public
        payable
        override
        auctionHasStarted
        auctionNotClosed
        minimumBid
    {
        if (highestBid > 0) {
            address payable refundee = payable(highestBidder);
            refundee.transfer(highestBid);
        } else if (endTime == 0) {
            endTime = block.timestamp + duration;
        }

        bids[msg.sender].push(
            Bid({amount: msg.value, timestamp: block.timestamp})
        );

        if (block.timestamp + extensionPeriod > endTime) {
            endTime = block.timestamp + extensionPeriod;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit BidReceived(msg.sender);
    }

    function finalize() public auctionClosed auctionNotFinalized {
        finalizedTime = block.timestamp;

        beneficiary.transfer(highestBid);

        emit AuctionFinalized(msg.sender);
    }
}
