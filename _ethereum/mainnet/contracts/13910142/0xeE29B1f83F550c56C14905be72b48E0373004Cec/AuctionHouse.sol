// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IAuctionHouse.sol";
import "./ITodayToken.sol";
import "./IWETH.sol";

import "./console.sol";

contract AuctionHouse is
    Initializable,
    IAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeMathUpgradeable for uint256;

    // The Today ERC721 token contract
    ITodayToken public todayToken;

    // The address of the WETH contract
    address public weth;

    address public teamAddress;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The duration of a single auction
    uint256 public duration;

    // The tokenId of currently active official auction
    uint256 public currentAuctionTokenId;

    // The minimum difference between the last bid amount and the current bid
    uint256 public minBidIncrement;

    mapping(uint256 => IAuctionHouse.Auction) public auctions;

    modifier onlyTeam() {
        require(msg.sender == teamAddress, "Sender is not team address");
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        ITodayToken _token,
        address _weth,
        address _teamAddress,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint256 _duration,
        uint256 _minBidIncrement
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        todayToken = _token;
        weth = _weth;
        teamAddress = _teamAddress;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrement = _minBidIncrement;
        duration = _duration;
    }

    /**
     * @notice Create a bid for a token, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 tokenId) external payable override nonReentrant {
        IAuctionHouse.Auction memory _auction = auctions[tokenId];

        require(_auction.tokenId == tokenId, "Token is not auctioned");
        require(block.timestamp >= _auction.startTime, "Auction does not start");
        require(block.timestamp < _auction.endTime, "Auction has already ended");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >= _auction.amount.add(minBidIncrement),
            "Must send more than last bid by minBidIncrement amount"
        );

        address payable lastBidder = _auction.bidder;

        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auctions[tokenId].amount = msg.value;
        auctions[tokenId].bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auctions[tokenId].endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function createAuction(string memory date) external whenNotPaused nonReentrant onlyTeam {
        try todayToken.mint(date) returns (uint256 tokenId) {
            uint256 startTime = block.timestamp;
            if (startTime < 1640995200) {
                startTime = 1640995200;
            }
            uint256 endTime = startTime + duration;
            auctions[tokenId] = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                tokenOwner: address(this),
                bidder: payable(0),
                settled: false
            });
            currentAuctionTokenId = tokenId;

            emit AuctionCreated(tokenId, startTime, endTime);
        } catch Error(string memory _error) {
            // console.log("Error: ", _error);
            revert(_error);
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev This function can only be called when the contract is paused.
     * @dev If there are no bids, the Noun is burned.
     */
    function settleAuction(uint256 tokenId) external override whenNotPaused nonReentrant {
        IAuctionHouse.Auction memory _auction = auctions[tokenId];

        require(_auction.startTime != 0, "Auction doesn't have startTime");
        require(!_auction.settled, "Auction has already been settled");
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        auctions[tokenId].settled = true;

        if (currentAuctionTokenId == tokenId) {
            currentAuctionTokenId = 0;
        }

        if (_auction.bidder == address(0)) {
            todayToken.burn(_auction.tokenId);
            delete auctions[tokenId];
            emit AuctionRemoved(tokenId);
        } else {
            todayToken.transferFrom(address(this), _auction.bidder, _auction.tokenId);
            auctions[tokenId].tokenOwner = _auction.bidder;
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
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     * If the receiver is a contract that doesn't implement receive() or fallback(), the method will return false.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /**
     * @notice Pause the todayToken auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the todayToken auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
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
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) external override onlyOwner {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrement(uint256 _minBidIncrement) external override onlyOwner {
        minBidIncrement = _minBidIncrement;

        emit AuctionMinBidIncrementUpdated(_minBidIncrement);
    }

    function setTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function currentAuction() external view override returns (Auction memory) {
        require(currentAuctionTokenId > 0, "AuctionHouse: no auction");
        return auctions[currentAuctionTokenId];
    }
}
