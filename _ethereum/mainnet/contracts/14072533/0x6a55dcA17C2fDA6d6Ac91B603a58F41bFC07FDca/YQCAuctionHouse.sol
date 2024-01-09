// SPDX-License-Identifier: GPL-3.0

/// @title The YQC DAO auction house

// LICENSE
// YQCAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Queeners DAO.

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IYQCAuctionHouse.sol";
import "./IYQCToken.sol";
import "./IWETH.sol";
import "./Math.sol";
import "./SafeMath.sol";

contract YQCAuctionHouse is IYQCAuctionHouse, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using Math for uint256;
    using SafeMath for uint256;

    // The YQC ERC721 token contract
    IYQCToken public queens;

    // The address of the WETH contract
    address public weth;

    // The address of the treasury contract
    address public treasury;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    mapping(uint256 => IYQCAuctionHouse.Bid) public bids;

    uint256 public maxSupply;

    uint256 public startTimeStamp;

    uint256 public startQueenId;

    address public queenersDAO;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IYQCToken _queens,
        address _queenersDAO,
        address _weth,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration,
        uint256 _maxSupply
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        queens = _queens;
        queenersDAO = _queenersDAO;
        weth = _weth;
        treasury = msg.sender;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        maxSupply = _maxSupply;

        startQueenId = 0;
    }

    /**
     * @notice Create a bid for a Queen, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 queenId) external payable override nonReentrant {
        require(block.timestamp >= startTimeStamp, 'Auction not started yet');
        require(queenId < maxSupply, 'No more queens available');
        require(currentQueenId() == queenId, 'Queen not up for auction');
        IYQCAuctionHouse.Bid memory _bid = bids[queenId];
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _bid.amount + ((_bid.amount * minBidIncrementPercentage) / 100),
            'Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _bid.bidder;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _bid.amount);
        }

        _bid.amount = msg.value;
        _bid.bidder = payable(msg.sender);
        bids[queenId] = _bid;

        emit AuctionBid(queenId, msg.sender, msg.value);
    }

    /**
     * @notice Pause the YQC auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        startQueenId = currentQueenId();
        _pause();
    }

    /**
     * @notice Unpause the YQC auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause(uint256 timestamp) external override onlyOwner {
        _unpause();
        startTimeStamp = timestamp;
    }

    /**
     * @notice Set the maxSupply.
     * @dev Only callable by the owner.
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Set the treasury.
     * @dev Only callable by the owner.
     */
    function setTreasury(address _treasury) external override onlyOwner {
        treasury = _treasury;

        emit AuctionTreasuryUpdated(_treasury);
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

    function mintQueenersQueens(uint256[] memory queenIds) external override nonReentrant {
        for (uint256 i = 0; i < queenIds.length; i++) {
            uint256 queenId = queenIds[i];
            require(queenId < maxSupply, 'No more queens available');
            require(currentQueenId() > queenId, "Queen not available yet");
            queens.mint(queenId, queenersDAO);
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Queen is burned.
     */
    function settleAuction(uint256 queenId) external override nonReentrant {
        IYQCAuctionHouse.Bid memory _bid = bids[queenId];
        require(_bid.bidder != address(0), 'No bids to settle');

        require(queenId < maxSupply, 'No more queens available');
        require(currentQueenId() > queenId, "Auction hasn't completed");
        require(!queens.exists(queenId), 'Auction has already been settled');

        queens.mint(queenId, _bid.bidder);
        if (_bid.amount > 0) {
            _safeTransferETHWithFallback(treasury, _bid.amount);
        }

        emit AuctionSettled(queenId, _bid.bidder, _bid.amount);
    }

    function currentAuction() public view returns (IYQCAuctionHouse.Auction memory) {
        return auction(currentQueenId());
    }

    function currentAuctionStartTimeStamp() public view returns (uint256) {
        return auctionStartTimeStamp(currentQueenId());
    }

    function currentQueenId() public view returns (uint256) {
        uint256 queenId = startQueenId;
        if (!paused() && block.timestamp > startTimeStamp) {
            uint256 intervals = block.timestamp.sub(startTimeStamp).ceilDiv(duration);
            uint256 blocks = intervals.ceilDiv(10).sub(startQueenId > 0 ? 1 : 0);
            queenId = startQueenId.add(intervals.sub(1).add(blocks.mul(3)));
        }
        return queenId;
    }

    function auction(uint256 queenId) public view returns (IYQCAuctionHouse.Auction memory) {
        uint256 ts = auctionStartTimeStamp(queenId);

        IYQCAuctionHouse.Auction memory auctionInfo;
        auctionInfo.queenId = queenId;

        IYQCAuctionHouse.Bid memory _bid = bids[queenId];
        auctionInfo.amount = _bid.amount;
        auctionInfo.bidder = _bid.bidder;
        auctionInfo.startTime = ts;
        auctionInfo.endTime = queens.isQueenersQueen(queenId) ? ts : ts.add(duration);
        auctionInfo.settled = queenId < currentQueenId() && (_bid.amount == 0 || queens.exists(queenId));

        return auctionInfo;
    }

    function auctionStartTimeStamp(uint256 queenId) public view returns (uint256) {
        uint256 timeStamp = startTimeStamp;
        if (queenId >= startQueenId) {
            queenId = queens.isQueenersQueen(queenId) ? (queenId.div(13).mul(13).add(3)) : queenId;
            uint256 blocks = queenId.sub(startQueenId).div(13);
            uint256 rem = startQueenId > 0 ? 0 : queenId.sub(3) % 13;
            timeStamp = startTimeStamp.add(blocks.mul(10).add(rem).mul(duration));
        }
        return timeStamp;
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
