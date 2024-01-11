// SPDX-License-Identifier: GPL-3.0

/// @title The NPC auction house

// LICENSE
// NPCAuctionHouse.sol is a modified version of Noun's AuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// NounAuctionHouse.sol source code Copyright Noun licensed under the GPL-3.0 license.
// With modifications by NPC.

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./UUPSUpgradeable.sol";
import "./INPCAuctionHouse.sol";
import "./INPC.sol";
import "./IWETH.sol";

interface INPC721 is INPC{
    function npcTracker() external view returns (uint256);
}

contract NPCAuctionHouse is INPCAuctionHouse, UUPSUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {

    // The NPC ERC721 token contract
    INPC721 public npc;

    // The address of the WETH contract
    address public weth;

    // The address of the NPC Treasury
    address public NPCTreasury;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    INPCAuctionHouse.Auction public auction;

    // mapping for past Auction amounts
    mapping(uint256 => uint256) private _pastAuctionAmounts;

    // counter for tracking current auction in progress
    uint256 private _currentAuctionId;

    // boolean for determining base contract used by proxy
    bool public baseContract;

    constructor(){ baseContract = true; }
    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        INPC721 _npc, 
        address _weth, 
        address _NPCTreasury,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage, // in basis points
        uint256 _duration
    ) external initializer {
        require(!baseContract, "base contract cannot be initialized");
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        npc = _npc;
        weth = _weth;
        NPCTreasury = _NPCTreasury;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        _currentAuctionId = 1;
    }

    /**
     * @notice Settle the current auction, mint a new NPC, and put it up for auction if all NPC aren't minted.
     */
    function settleCurrentAndCreateNewAuction() external override nonReentrant whenNotPaused {
        _settleAuction();
        if(npc.npcTracker() < 333){
            _createAuction();
        }
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a NPC, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 npcId) external payable override nonReentrant {
        INPCAuctionHouse.Auction memory _auction = auction;

        require(_auction.npcId == npcId, 'NPC not up for auction');
        require(block.timestamp < _auction.endTime, 'Auction expired');
        require(msg.value >= reservePrice, 'Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 10000),
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

        emit AuctionBid(_auction.npcId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.npcId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the NPC auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the NPC auction house.
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
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try npc.mint() returns (uint256 npcId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            uint256 lastAuction = _currentAuctionId - 1;
            uint256 initialBid;

            if(lastAuction >= 3){
                uint256 price1 = _pastAuctionAmounts[lastAuction];
                uint256 price2 = _pastAuctionAmounts[lastAuction - 1];
                uint256 price3 = _pastAuctionAmounts[lastAuction - 2];

                initialBid = ((price1 + price2 + price3) / 3);
                uint256 percentage = (initialBid * 1000) / 10000;

                initialBid = initialBid + percentage;
            }

            else{ initialBid = 0; }

            auction = Auction({
                npcId: npcId,
                amount: initialBid,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(npcId, startTime, endTime);
        } catch Error(string memory) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        INPCAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn`t begun");
        require(!_auction.settled, 'Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Auction hasn`t completed");

        auction.settled = true;
        bool npcBurned;

        if (_auction.bidder == address(0)) {
            npc.burn(_auction.npcId);
            npcBurned = true;
        } else {
            npc.transferFrom(address(this), _auction.bidder, _auction.npcId);
        }

        if (_auction.amount > 0 && !npcBurned) {
            _safeTransferETHWithFallback(NPCTreasury, _auction.amount);
        }

        _pastAuctionAmounts[_currentAuctionId++] = auction.amount;

        emit AuctionSettled(_auction.npcId, _auction.bidder, _auction.amount);
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

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}