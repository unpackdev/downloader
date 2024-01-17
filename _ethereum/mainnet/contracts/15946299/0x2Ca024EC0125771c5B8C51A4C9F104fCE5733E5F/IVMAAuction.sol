// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


interface IVMAAuction {
    struct Auction {
        uint256 alphaId;
        uint256 price;// currently the highest bid price
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    event AuctionCreated(uint256 indexed alphaId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed alphaId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed alphaId, uint256 endTime);

    event AuctionCreateFailed(string error);

    event AuctionRefundFailed(address indexed winner, uint256 amount);

    event AuctionSettled(uint256 indexed alphaId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event AuctionGasUpdated(uint256 gas);


    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 alphaId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}