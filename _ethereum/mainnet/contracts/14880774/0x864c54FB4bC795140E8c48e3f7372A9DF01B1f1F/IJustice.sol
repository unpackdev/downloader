// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IJustice {

    struct Auction {
        // Fixed-size array of max 3 members for specifiying splits from sales
        // 0 = pr1s0nartPayment, 1 = pr1s0nartFund, 2 = creatorAddress
        uint8[3] saleSplit;
        // address of creator. If they have none, we use pr1s0nartPayment 
        address creator;
        // ID for the Art (ERC721 token ID)
        uint256 tokenId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed tokenId, uint8[3] saleSplit, address creator, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed tokenId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);

    event AuctionSettled(uint256 indexed tokenId, address winner, uint256 amount);

    event NoBuyer(uint256 indexed tokenId);

    event PaymentAddressUpdated(address newPayment);

    event FundAddressUpdated(address newFund);

    event AuctionDurationUpdated(uint256 newDuration);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction() external;

    function createBid(uint256 tokenId) external payable;

    function setPaymentAddress(address newPayment) external;

    function setFundAddress(address newFund) external;

    function setDuration(uint256 duration) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

}