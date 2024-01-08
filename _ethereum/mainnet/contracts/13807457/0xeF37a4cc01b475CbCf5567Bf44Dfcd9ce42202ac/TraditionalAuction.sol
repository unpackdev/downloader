// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./Auction.sol";

contract TraditionalAuction is MonegraphAuction {
    event AuctionCreated(string metadata, uint256 quantity);

    event BidReceived(address bidder);
    event AuctionFinalized(address from);

    uint256 public constant maximumIncrease = 100000000000000000 wei;

    function initialize(
        Beneficiary[] memory _beneficaries,
        string memory _metadata,
        uint256 _initialBidAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _quantity
    ) public override {
        super.initialize(
            _beneficaries,
            _metadata,
            _initialBidAmount,
            _startTime,
            _endTime,
            _quantity
        );

        emit AuctionCreated(metadata, _quantity);
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
        external
        payable
        override
        auctionHasStarted
        auctionNotClosed
        minimumBid
    {
        uint256 currentHighBid = highestBid;
        highestBid = msg.value;

        if (quantity > 1) {
            if (bids.length >= quantity) {
                Bid memory refundedBid = bids[bids.length - quantity];

                if (refundedBid.refunded == false && refundedBid.amount > 0) {
                    refundedBid.refunded = true;

                    address payable refundee = payable(refundedBid.bidder);

                    (bool success, ) = refundee.call{
                        value: refundedBid.amount,
                        gas: 20000
                    }("");

                    if (!success) {
                        payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9)
                            .transfer(refundedBid.amount);
                    }
                }
            }
        } else {
            if (currentHighBid > 0) {
                address payable refundee = payable(highestBidder);

                (bool success, ) = refundee.call{
                    value: currentHighBid,
                    gas: 20000
                }("");

                if (!success) {
                    payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9)
                        .transfer(currentHighBid);
                }
            }
        }

        if (endTime == 0) {
            endTime = block.timestamp + duration;
        }

        bids.push(
            Bid({
                bidder: msg.sender,
                amount: msg.value,
                timestamp: block.timestamp,
                refunded: false
            })
        );

        if (block.timestamp + extensionPeriod > endTime) {
            endTime = block.timestamp + extensionPeriod;
        }

        highestBidder = msg.sender;

        emit BidReceived(msg.sender);
    }

    function finalize() external auctionClosed auctionNotFinalized {
        finalizedTime = block.timestamp;
        uint256 value = address(this).balance;

        require(value > 0, "Auction had no bids and can not be finalized");

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            Beneficiary memory beneficiary = beneficiaries[i];

            uint256 amount = (value / 100) * beneficiary.percentage;

            (bool success, ) = beneficiary.wallet.call{
                value: amount,
                gas: 20000
            }("");

            if (!success) {
                payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9).transfer(
                    amount
                );
            }
        }

        emit AuctionFinalized(msg.sender);
    }
}
