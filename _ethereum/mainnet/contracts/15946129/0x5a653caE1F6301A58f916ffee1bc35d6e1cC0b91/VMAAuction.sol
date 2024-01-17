// SPDX-License-Identifier: GPL-3.0

// LICENSE
// VMAAuction.sol is a modified version of Nouns' NounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// VMAAuction.sol source code Copyright LOVO licensed under the GPL-3.0 license.
// With modifications by Nounders DAO.

pragma solidity ^0.8.16;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IVMAAuction.sol";
import "./IVoiceMaskAlpha.sol";

contract VMAAuction is IVMAAuction, Pausable, ReentrancyGuard, Ownable {
    IVoiceMaskAlpha public voiceMaskAlpha;

    uint256 public timeBuffer;

    uint256 public reservePrice;

    uint256 public durationTime;

    uint256 public gas;

    uint8 public minBidIncrementPercentage;

    IVMAAuction.Auction public auction;

    constructor(
        IVoiceMaskAlpha _alpha, //alpha nft
        uint256 _timeBuffer, // padding time. 300 = 5min
        uint256 _reservePrice, // at least 0
        uint256 _durationTime, // 43200 = 12hrs
        uint8 _minBidIncrementPercentage // 2%
    ) {
        _pause();

        voiceMaskAlpha = _alpha;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        durationTime = _durationTime;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        gas = 30000;
    }

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
     * Settle the current auction.
     * This function can be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * Create a bid for an Alpha, with a given value.
     */
    function createBid(uint256 alphaId)
        external
        payable
        override
        whenNotPaused
        nonReentrant
    {
        IVMAAuction.Auction memory _auction = auction;

        require(block.timestamp < _auction.endTime, "Auction is expired");
        require(_auction.alphaId == alphaId, "Not for this auction");
        require(msg.value >= reservePrice, "Send at least reservePrice");
        require(
            msg.value >=
                _auction.price +
                    ((_auction.price * minBidIncrementPercentage) / 100),
            "Increase the bid by minBidIncrementPercentage"
        );

        address payable lastBidder = _auction.bidder;
        require(msg.sender != lastBidder, "Wait for next turn");

        // Refund the last bidder
        if (lastBidder != address(0)) {
            _transferETH(lastBidder, _auction.price);
        }

        auction.price = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if bidded within timeBuffer time before the auction ends.
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.alphaId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.alphaId, _auction.endTime);
        }
    }

    /**
     * Pause the auction.
     * CreateBid is unactivated by this function.
     * The auction can be settled by anyone after the endtime has passed.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * Unpause the auction.
     * If there is no active auction, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }

    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

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

    function setGas(uint256 _gas) external onlyOwner {
        require(_gas >= 21000, "Gas is not enough for transaction");
        gas = _gas;

        emit AuctionGasUpdated(gas);
    }

    function setDuration(uint256 _durationTime) external onlyOwner {
        durationTime = _durationTime;
    }

    /**
     * Create an auction.
     * Store the auction details in the auction state variable.
     * If the mint reverts, the contract will be paused.
     */
    function _createAuction() internal {
        try voiceMaskAlpha.mintAuction() returns (uint256 alphaId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + durationTime;

            auction = Auction({
                alphaId: alphaId,
                price: 0, //입찰가
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(alphaId, startTime, endTime);
        } catch Error(string memory error) {
            _pause();
            emit AuctionCreateFailed(error);
        }
    }

    /**
     *  Settle an auction. Finish the bid and payment.
     *  If there is no bid the Alpha NFT will be send to the owner's EOA.
     */
    function _settleAuction() internal {
        IVMAAuction.Auction memory _auction = auction;

        require(block.timestamp >= _auction.endTime, "Auction is active");
        require(!_auction.settled, "Auction is settled already");
        require(_auction.startTime != 0, "Auction didn't start yet");

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            // No one made a bid
            voiceMaskAlpha.transferFrom(
                address(this),
                owner(),
                _auction.alphaId
            );
        } else {
            voiceMaskAlpha.transferFrom(
                address(this),
                _auction.bidder,
                _auction.alphaId
            );
        }

        if (_auction.price > 0) {
            //send money to the owner EOA
            _transferETH(owner(), _auction.price);
        }

        emit AuctionSettled(_auction.alphaId, _auction.bidder, _auction.price);
    }

    /**
     * Transfer ETH.
     */
    function _transferETH(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            emit AuctionRefundFailed(to, amount);
        }
    }

    /**
     * Transfer ETH and return the success status.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: gas}(new bytes(0));
        return success;
    }
}
