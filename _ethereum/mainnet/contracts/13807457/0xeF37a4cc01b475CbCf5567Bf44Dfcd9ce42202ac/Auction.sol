// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./Initializable.sol";

abstract contract MonegraphAuction is Initializable {    
    string public metadata;

    address public highestBidder;
    uint256 public highestBid;

    uint256 public initialBidAmount;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public finalizedTime;

    uint256 public constant duration = 86400;
    uint256 public constant extensionPeriod = 900;

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
        bool refunded;
    }

    struct Beneficiary {
        uint8 percentage;
        address payable wallet;
    }

    Beneficiary[] public beneficiaries;

    Bid[] public bids;

    uint256 public quantity;

    modifier notZeroAddress(address addr) {
        require(addr != address(0));
        _;
    }

    modifier onlyBefore(uint256 _time) {
        require(block.timestamp < _time);
        _;
    }

    modifier onlyAfter(uint256 _time) {
        require(block.timestamp > _time);
        _;
    }

    modifier auctionHasStarted() {
        require(startTime <= block.timestamp, "Auction has not started yet");
        _;
    }

    modifier auctionNotClosed() {
        require(
            endTime == 0 || endTime >= block.timestamp,
            "Auction already ended."
        );
        _;
    }

    modifier auctionClosed() {
        require(
            endTime != 0 && endTime <= block.timestamp,
            "This auction is still active"
        );
        _;
    }

    modifier auctionNotFinalized() {
        require(finalizedTime == 0, "Auction has already been finalized");
        _;
    }

    function initialize(
        Beneficiary[] memory _beneficiaries,
        string memory _metadata,
        uint256 _initialBidAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _quantity
    ) public virtual initializer {
         _startTime = _startTime > 0 && _startTime > block.timestamp
            ? _startTime
            : block.timestamp;

        endTime = _endTime > 0 && _endTime > block.timestamp ? _endTime : 0;

        for (uint i=0; i<_beneficiaries.length; i++) {
            beneficiaries.push(_beneficiaries[i]);
        }

        metadata = _metadata;
        initialBidAmount = _initialBidAmount;
        startTime = _startTime;
        quantity = _quantity;
    }

    function bid() external payable virtual;
}
