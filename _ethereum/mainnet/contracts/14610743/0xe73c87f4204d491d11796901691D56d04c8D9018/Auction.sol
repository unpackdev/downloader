// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "IAuction.sol";
import "INFTContract.sol";
import "NFTCommon.sol";


contract Auction is IAuction {
    using NFTCommon for INFTContract;

    /// State variables

    address private immutable ADMIN;
    mapping(address => uint256) public bids;

    uint256 public constant MINIMUM_BID_INCREMENT = 0.1 ether;

    uint256 public floorPrice;
    uint256 public auctionEndTimestamp;
    INFTContract public whitelistedCollection;

    bool private auctionActive = false;
    bool private initialized = false;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    /// Constructor

    constructor() {
        ADMIN = msg.sender;
    }

    /// Init

    /// @inheritdoc IAuction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndTimestamp,
        INFTContract initWhitelistedCollection
    ) external override {
        if (tx.origin != ADMIN) revert NotAdmin();
        if (initialized) revert AlreadyInitialized();

        floorPrice = initFloorPrice;
        auctionEndTimestamp = initAuctionEndTimestamp;
        whitelistedCollection = initWhitelistedCollection;

        initialized = true;
    }

    /// Receiver

    /// @dev Reject direct contract payments
    receive() external payable {
        revert RejectDirectPayments();
    }

    /// Check if Whitelisted, Place Bid

    function checkIfWhitelisted(uint256 tokenID) internal view {
        // ! be very careful with this
        // ! only whitelist the collections with trusted code
        // ! you are giving away control here to the nft contract
        // ! for balance checking purposes, but the code can be
        // ! anything

        // if address is zero, any collection can bid
        if (address(whitelistedCollection) == address(0)) {
            return;
        }

        uint256 sendersBalance = whitelistedCollection.quantityOf(
            address(msg.sender),
            tokenID
        );

        if (sendersBalance == 0) {
            revert BidForbidden();
        }
    }

    /// @inheritdoc IAuction
    function placeBid(uint256 tokenID) external payable override {
        if (!auctionActive) revert AuctionNotActive();
        if (msg.value <= 0) revert NoEtherSent();
        checkIfWhitelisted(tokenID);

        /// Ensures that if the bidder has an existing bid, the delta that
        /// he sent, is at least MINIMUM_BID_INCREMENT
        if (bids[msg.sender] > 0) {
            if (msg.value < MINIMUM_BID_INCREMENT) {
                revert LessThanMinIncrement({actualSent: msg.value});
            }
        } else {
            /// If this is the first bid, then make sure it's higher than
            /// the floor price
            if (msg.value < floorPrice)
                revert LessThanFloorPrice({actualSent: msg.value});
        }

        bids[msg.sender] += msg.value;

        emit PlaceBid({bidder: msg.sender, price: msg.value});

        if (block.timestamp >= auctionEndTimestamp) endAuction();
    }

    function endAuction() internal {
        auctionActive = false;
        emit EndAuction();
    }

    /// Admin

    function startAuction() external override onlyOwner {
        auctionActive = true;
        emit StartAuction();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(ADMIN).call{value: address(this).balance}(
            ""
        );
        if (!success) revert TransferFailed();
    }
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * Auction.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
