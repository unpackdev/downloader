// SPDX-License-Identifier: GPL-3.0
/// @title The Rakuten Monkey Sponsors Club auction house

// LICENSE
// AuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by warrencheng.eth.

pragma solidity ^0.8.6;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IWETH.sol";

interface NFT is IERC721 {
    function mint(address receiver) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}

struct Auction {
    // NFT TokenId
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

contract AuctionHouse is Pausable, ReentrancyGuard, Ownable {
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed tokenId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionDurationUpdated(uint256 duration);

    event AuctionMinBidIncrementUpdated(uint256 minBidIncrement);

    // The ERC721 token contract
    address public rmsc;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum wei difference between the last bid amount and the current bid
    uint256 public minBidIncrement;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    Auction public auction;

    constructor(
        address _rmsc,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint256 _minBidIncrement,
        uint256 _duration
    ) {
        _pause();

        rmsc = _rmsc;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrement = _minBidIncrement;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
        nonReentrant
        whenNotPaused
    {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 tokenId) external payable nonReentrant {
        Auction memory _auction = auction;
        require(_auction.tokenId == tokenId, "Noun not up for auction");
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >= _auction.amount + minBidIncrement,
            "Must send more than last bid by minBidIncrement amount"
        );
        address payable lastBidder = _auction.bidder;
        uint256 lastBidAmount = _auction.amount;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, lastBidAmount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction duration.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
    }

    /**
     * @notice Set the auction minimum bid increment .
     * @dev Only callable by the owner.
     */
    function setMinBidIncrement(uint8 _minBidIncrement) external onlyOwner {
        minBidIncrement = _minBidIncrement;

        emit AuctionMinBidIncrementUpdated(_minBidIncrement);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try NFT(rmsc).mint(address(this)) returns (uint256 tokenId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(tokenId, startTime, endTime);
        } catch Error(string memory err) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        Auction memory _auction = auction;
        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            NFT(rmsc).burn(_auction.tokenId);
        } else {
            NFT(rmsc).transferFrom(
                address(this),
                _auction.bidder,
                _auction.tokenId
            );
        }
        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}
