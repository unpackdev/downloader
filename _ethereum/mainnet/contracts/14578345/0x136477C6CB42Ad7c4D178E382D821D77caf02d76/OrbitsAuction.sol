// SPDX-License-Identifier: GPL-3.0

/// @title The Orbits auction house

pragma solidity ^0.8.6;

import "./IWETH.sol";
import "./IOrbitsNFT.sol";
import "./IOrbitsAuction.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract OrbitsAuction is IOrbitsAuction, Pausable, ReentrancyGuard, Ownable {
    // The Orbit ERC721 token contract
    IOrbitsNFT public orbits;

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
    IOrbitsAuction.Auction public auction;

    // Whether the whitelist is active
    bool public isWhitelistActive;

    // Mapping for whether an address is whitelisted to bid
    mapping(address => bool) public isWhitelisted;

    constructor (
        IOrbitsNFT _orbits,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) {
        _pause();

        orbits = _orbits;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /************
    *  SETTERS  *
    *************/

    /**
     * @notice Pause the orbits auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the orbits auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();
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
     * @notice Set the auction duration.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit DurationUpdated(_duration);
    }

    /**
     * @notice Set the whitelist status
     * @dev Only callable by the owner.
     */
    function setWhitelistStatus(bool whitelistStatus) external override onlyOwner {
        isWhitelistActive = whitelistStatus;

        emit WhitelistStatusChanged(whitelistStatus);
    }

    /**
     * @notice Whitelist an address
     * @dev Only callable by the owner.
     */
    function addToWhitelist(address[] calldata whitelist) external override onlyOwner {
        for (uint i;i < whitelist.length;i++){
            isWhitelisted[whitelist[i]] = true;
        }
    }

    /**
     * @notice Alter the whitelist
     * @dev Only callable by the owner.
     */
    function alterWhitelist(address[] calldata whitelist, bool[] calldata status) external override onlyOwner {
        require(whitelist.length == status.length);
        for (uint i;i < whitelist.length;i++){
            isWhitelisted[whitelist[i]] = status[i];
        }
    }

    /**
     * @notice De-Whitelist an address
     * @dev Only callable by the owner.
     */
    function removeFromWhitelist(address[] calldata whitelist) external override onlyOwner {
        for (uint i;i < whitelist.length;i++){
            isWhitelisted[whitelist[i]] = false;
        }
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

    /*************
    *  EXTERNAL  *
    **************/

    /**
     * @notice Create a new auction.
     */
    function createAuction(string calldata _tokenURI) external onlyOwner override whenNotPaused {
        _createAuction(_tokenURI);
    }

    /**
     * @notice Settle the current auction.
     */
    function settleAuction() external override whenNotPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Orbit, with a given amount. If the whitelist is active
     *         check if the caller is whitelisted
     * @param  orbitId the orbit to bid on
     * @dev    This contract only accepts payment in ETH.
     */
    function createBid(uint256 orbitId) external payable override nonReentrant {
        if (isWhitelistActive) {
            require(isWhitelisted[msg.sender], "!whitelisted");
        }
        IOrbitsAuction.Auction memory _auction = auction;

        require(_auction.orbitId == orbitId, 'Orbit not up for auction');
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

        emit AuctionBid(_auction.orbitId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.orbitId, _auction.endTime);
        }
    }

    /*************
    *  INTERNAL  *
    **************/

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction(string calldata _tokenURI) internal {
        try orbits.mint(_tokenURI) returns (uint256 orbitId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                orbitId: orbitId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(orbitId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Orbit is burned.
     */
    function _settleAuction() internal {
        IOrbitsAuction.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            orbits.burn(_auction.orbitId);
        } else {
            orbits.transferFrom(address(this), _auction.bidder, _auction.orbitId);
        }

        if (_auction.amount > 0) {
            _safeTransferETHWithFallback(owner(), _auction.amount);
        }

        emit AuctionSettled(_auction.orbitId, _auction.bidder, _auction.amount);
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