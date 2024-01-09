// SPDX-License-Identifier: GPL-3.0

/// @title The Sunrise Art Club auction house

// LICENSE
// SunriseAuctionHouse.sol is a modified version of NounDAO's NounsAuctionHouse.sol.
// SunriseAuctionHouse.sol source code Copyright NounsDAO licensed under the GPL-3.0 license.
// with modifications by Sunrise Art Club.

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./ISunriseAuctionHouse.sol";
import "./ISunriseToken.sol";
import "./IWETH.sol";

contract SunriseAuctionHouse is
    ISunriseAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    // The Sunrise ERC721 token contract
    ISunriseToken public sunrise;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    ISunriseAuctionHouse.Auction public auction;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        ISunriseToken _sunrise,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        sunrise = _sunrise;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    /**
     * @notice Settle the current auction, mint a new Sunrise, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Sunrise, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 sunriseId) external payable override nonReentrant {
        ISunriseAuctionHouse.Auction memory _auction = auction;

        require(_auction.sunriseId == sunriseId, 'Sunrise not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.sunriseId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.sunriseId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Sunrise auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Sunrise auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Set the auction duration bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try sunrise.mint() returns (uint256 sunriseId) {
            // linear decay with remaining seconds distributed equally
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                sunriseId: sunriseId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false,
                duration: duration
            });

            emit AuctionCreated(sunriseId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Sunrise is sent the owner of the contract.
     */
    function _settleAuction() internal {
        ISunriseAuctionHouse.Auction memory _auction = auction;

        address _sunriseArtClub = 0x2EfDC5AEC299BF959cb0f0D8fF42268686731614; // Sunrise Art Club
        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder != address(0)) {
            sunrise.transferFrom(address(this), _auction.bidder, _auction.sunriseId);
        }

        if (_auction.amount > 0) {
            // Withdrawl addresses
            address _swopes = 0x18C5eA5B6441D99d621cEC21e9c034d97124d267; // Swopes
            address _lauren = 0xD5F7818b117193509382E734c9C4EBB517461B9a; // Lauren
            address _eddie = 0x23a6d68404fEb930665B05747a177Fd4C45Df348; // Eddie
            address _dan = 0xDF1c02cbc90214834119681a842E6b906672c81a; // Dan
            address _ann = 0xb2c21980dDb10AEEfa8aB10CF79A036AfF89376E; // Ann
            address _jetzi = 0x497dcC4271602fB81486A7Ab5600B7d50455CAc5; // Jetzi
            address _community = 0x454d958AaaB3fa7857B8Eb17C9F5655Bb28D36a1; // Community Support

            _safeTransferETHWithFallback(_sunriseArtClub, (_auction.amount * 7500) / 10000); // 75%
            _safeTransferETHWithFallback(_swopes, (_auction.amount * 1050) / 10000); // 10.5%
            _safeTransferETHWithFallback(_lauren, (_auction.amount * 625) / 10000); // 6.25%
            _safeTransferETHWithFallback(_eddie, (_auction.amount * 250) / 10000); // 2.5%
            _safeTransferETHWithFallback(_dan, (_auction.amount * 250) / 10000); // 2.5%
            _safeTransferETHWithFallback(_ann, (_auction.amount * 125) / 10000); // 1.25%
            _safeTransferETHWithFallback(_jetzi, (_auction.amount * 100) / 10000); // 1%
            _safeTransferETHWithFallback(_community, (_auction.amount * 100) / 10000); // 1%
        }

        // Send to Sunrise Art Club wallet if no bids have been placed
        address winner = _auction.bidder == address(0) ? _sunriseArtClub : _auction.bidder;
        emit AuctionSettled(_auction.sunriseId, winner, _auction.amount);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

}
