// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns DAO auction house

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// NounsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Nounders DAO.

pragma solidity ^0.8.6;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AuctionHouseStorage.sol";
import "./IWETH.sol";
import "./IAuctionHouse.sol";
import "./console.sol";

contract AuctionHouse is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    AuctionHouseStorage,
    IAuctionHouse
{
    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        ISnoopDAONFT _snoopDAONFT,
        address _dog,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        snoopDAONFT = _snoopDAONFT;
        dog = _dog;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction, mint a new Noun, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
        override
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
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Noun, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 snoopDAONFTId, uint256 amount)
        external
        override
        nonReentrant
    {
        IAuctionHouse.Auction memory _auction = auction;

        require(
            _auction.snoopDAONFTId == snoopDAONFTId,
            "Noun not up for auction"
        );
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(amount >= reservePrice, "Must send at least reservePrice");
        require(
            amount >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        IERC20(dog).transferFrom(msg.sender, address(this), amount);

        address lastBidder = _auction.bidder;
        uint256 lastBidAmount = _auction.amount;

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            IERC20(dog).transfer(lastBidder, lastBidAmount);
        }

        auction.amount = amount;
        auction.bidder = msg.sender;

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.snoopDAONFTId, msg.sender, amount, extended);

        if (extended) {
            emit AuctionExtended(_auction.snoopDAONFTId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
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
    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction duration.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        override
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * @notice Get auction duration
     * @dev 24 auctions = 1st day, 12 auctions = 2nd day, 6 auctions = 3rd day, 3 auctions = 4th day, 2 auction = 5th day,
     *      then use duration (initialised at 24 hours per)
     */
    function _getAuctionDuration(uint256 snoopDAONFTId)
        internal
        view
        returns (uint256)
    {
        if (snoopDAONFTId <= 23) {
            return 1 hours;
        } else if (snoopDAONFTId <= 35) {
            return 2 hours;
        } else if (snoopDAONFTId <= 41) {
            return 4 hours;
        } else if (snoopDAONFTId <= 44) {
            return 8 hours;
        } else if (snoopDAONFTId <= 46) {
            return 12 hours;
        } else {
            return duration;
        }
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try snoopDAONFT.mint(address(this)) returns (uint256 snoopDAONFTId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + _getAuctionDuration(snoopDAONFTId);

            auction = Auction({
                snoopDAONFTId: snoopDAONFTId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: address(0),
                settled: false
            });

            emit AuctionCreated(snoopDAONFTId, startTime, endTime);
        } catch Error(string memory err) {
            _pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Noun is burned.
     */
    function _settleAuction() internal {
        IAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            snoopDAONFT.burn(_auction.snoopDAONFTId);
        } else {
            snoopDAONFT.transferFrom(
                address(this),
                _auction.bidder,
                _auction.snoopDAONFTId
            );
        }

        if (_auction.amount > 0) {
            uint256 amountToSnoopDao = (_auction.amount * 90) / 100;
            uint256 amountToSquidDao = _auction.amount - amountToSnoopDao;
            address squidDaoMultiSig = 0x42E61987A5CbA002880b3cc5c800952a5804a1C5;
            IERC20(dog).transfer(owner(), amountToSnoopDao);
            IERC20(dog).transfer(squidDaoMultiSig, amountToSquidDao);
        }

        emit AuctionSettled(
            _auction.snoopDAONFTId,
            _auction.bidder,
            _auction.amount
        );
    }

    /**
     * @dev _authorizeUpgrade is used by UUPSUpgradeable to determine if it's allowed to upgrade a proxy implementation.
     //     added onlyOwner modifier for access control
     * @param newImplementation The new implementation
     *
     * Ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
