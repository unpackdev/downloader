// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IDutchAuction.sol";

/**
 * @title Dutch Auction contract made by Artiffine.
 * @author https://artiffine.com/
 */
contract DutchAuction is IDutchAuction, Ownable {
    uint256 public startTime; // Auction start time.
    uint256 public stepTime; // How many seconds is one auction round.
    uint256 public startPrice; // Start price of auction in wei.
    uint256 public priceDiscount; // Price discount every round in wei.
    uint256 public finalPrice; // Final price of auction in wei.

    error AuctionIsClosed();
    error StartTimeNotInTheFuture();
    error StepTimeIsZero();
    error StartPriceIsZero();
    error DiscountIsZero();
    error WrongAuctionSetup();

    constructor(uint256 _startTime, uint256 _stepTime, uint256 _startPrice, uint256 _priceDiscount, uint256 _finalPrice) {
        startAuction(_startTime, _stepTime, _startPrice, _priceDiscount, _finalPrice);
    }

    /**
     * @notice Returns current price auction in wei.
     *
     * @dev Throws `AuctionIsClosed()` error.
     */
    function getAuctionPrice() external view returns (uint256) {
        if (block.timestamp < startTime) revert AuctionIsClosed();
        uint256 maxSteps = (startPrice - finalPrice) / priceDiscount;
        uint256 timeElapsed = block.timestamp - startTime;
        uint256 currentStep = timeElapsed / stepTime;
        uint256 price;
        if (currentStep >= maxSteps) {
            price = finalPrice;
        } else {
            price = startPrice - (currentStep * priceDiscount);
        }
        assert(price >= finalPrice);
        return price;
    }

    /**
     * @notice Owner function to reset auction paramters.
     */
    function resetAuction(
        uint256 _startTime,
        uint256 _stepTime,
        uint256 _startPrice,
        uint256 _priceDiscount,
        uint256 _finalPrice
    ) external onlyOwner {
        startAuction(_startTime, _stepTime, _startPrice, _priceDiscount, _finalPrice);
    }

    function startAuction(
        uint256 _startTime,
        uint256 _stepTime,
        uint256 _startPrice,
        uint256 _priceDiscount,
        uint256 _finalPrice
    ) internal {
        if (_startTime <= block.timestamp) revert StartTimeNotInTheFuture();
        if (_stepTime == 0) revert StepTimeIsZero();
        if (_startPrice == 0) revert StartPriceIsZero();
        if (_priceDiscount == 0) revert DiscountIsZero();
        if (_startPrice - _priceDiscount < _finalPrice) revert WrongAuctionSetup();
        startTime = _startTime;
        stepTime = _stepTime;
        startPrice = _startPrice;
        priceDiscount = _priceDiscount;
        finalPrice = _finalPrice;
    }
}
