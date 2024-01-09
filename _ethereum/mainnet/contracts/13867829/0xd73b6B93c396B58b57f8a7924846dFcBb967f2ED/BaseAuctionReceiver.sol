// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./BytesLib.sol";
import "./LockableReceiver.sol";

abstract contract BaseAuctionReceiver is LockableReceiver {
    
    enum PriceDirection { NONE, UP, DOWN }

    struct PriceSettings { 
        uint startingPrice;
        uint finalPrice;
        uint priceChangePeriod; //in hours
        uint priceChangeStep; 
        PriceDirection direction;
        uint timestampAddedAt; 
    }

    using SafeMath for uint;

    mapping(uint => PriceSettings) internal _priceSettings;
    uint private _fees100;

    constructor (address accessControl, address dragonToken, uint fees100) 
    LockableReceiver(accessControl, dragonToken) {
        _fees100 = fees100;
    }

    function weiMinPrice() internal virtual pure returns (uint) {
        return 0;
    }

    function maxTotalPeriod() internal virtual pure returns (uint) {
        return 0;
    }

    /**
    * Defines how often the price is changed during 1 hour. 60 by default (every minute).
    */
    function numOfPriceChangesPerHour() internal virtual pure returns (uint) {
        return 60;
    }

    function feesPercent() public virtual view returns (uint) {
        return _fees100;
    }

    function updateFeesPercent(uint newFees100) external virtual onlyRole(CFO_ROLE) {
        _fees100 = newFees100;
    }

    function calcFees(uint weiAmount, uint fees100) internal virtual pure returns (uint) {
        return weiAmount.div(1e4).mul(fees100);
    }

    function readPriceSettings(bytes calldata data) internal virtual pure returns (uint, uint, uint) {
        uint weiStartingPrice = BytesLib.toUint256(data, 0);
        uint weiFinalPrice = BytesLib.toUint256(data, 0x20);
        uint totalPriceChangePeriod = BytesLib.toUint256(data, 0x40);
        return (weiStartingPrice, weiFinalPrice, totalPriceChangePeriod);
    } 

    function processERC721(address /*from*/, uint tokenId, bytes calldata data) 
        internal virtual override {

        (uint weiStartingPrice, uint weiFinalPrice, uint totalPriceChangePeriod) = 
            readPriceSettings(data);

        uint _weiMinPrice = weiMinPrice();
        uint _maxTotalPeriod = maxTotalPeriod();

        if (_weiMinPrice > 0) {
            require(weiStartingPrice >= _weiMinPrice && weiFinalPrice >= _weiMinPrice, 
                "BaseAuctionReceiver: the starting price and the final price cannot be less than weiMinPrice()");
        }
        if (_maxTotalPeriod > 0) {
            require(totalPriceChangePeriod <= _maxTotalPeriod, 
                "BaseAuctionReceiver: the price change period cannot exceed maxTotalPeriod()");
            require(totalPriceChangePeriod >= 12 && totalPriceChangePeriod.mod(12) == 0, 
                "BaseAuctionReceiver: the price change period should be a multiple of 0.5 days");
        }

        uint step;
        PriceDirection d;
        (step, d) = calcPriceChangeStep(
            weiStartingPrice, weiFinalPrice, totalPriceChangePeriod, numOfPriceChangesPerHour());
        PriceSettings memory settings = PriceSettings ({
            startingPrice: weiStartingPrice,
            finalPrice: weiFinalPrice,
            priceChangePeriod: totalPriceChangePeriod,
            priceChangeStep: step,
            direction: d,
            timestampAddedAt: block.timestamp
        });
        _priceSettings[tokenId] = settings;
    }

    function priceSettingsOf(uint tokenId) public view returns (PriceSettings memory) {
        return _priceSettings[tokenId];
    }

    function priceOf(uint tokenId) public view returns (uint) {
        PriceSettings memory settings = priceSettingsOf(tokenId);
        if (settings.direction == PriceDirection.NONE) {
            return settings.startingPrice;
        }

        uint max = Math.max(settings.startingPrice, settings.finalPrice);
        uint min = Math.min(settings.startingPrice, settings.finalPrice);
        uint diff = max.sub(min);

        uint totalNumOfPeriodsToFinalPrice = diff.div(settings.priceChangeStep);
        uint numOfPeriods = 
            (block.timestamp - settings.timestampAddedAt).div(60)
            .mul(numOfPriceChangesPerHour()).div(60);

        uint result;
        if (numOfPeriods > totalNumOfPeriodsToFinalPrice) {
            result = settings.finalPrice;
        }
        else if (settings.direction == PriceDirection.DOWN) {
            result = settings.startingPrice.sub(settings.priceChangeStep.mul(numOfPeriods));
        }
        else {
            result = settings.startingPrice.add(settings.priceChangeStep.mul(numOfPeriods));
        }
        return result;
    }

    function calcPriceChangeStep(
        uint weiStartingPrice, 
        uint weiFinalPrice, 
        uint totalPriceChangePeriod,
        uint _numOfPriceChangesPerHour) internal virtual pure returns (uint, PriceDirection) {

        if (weiStartingPrice == weiFinalPrice) {
            return (0, PriceDirection.NONE);
        }

        uint max = Math.max(weiStartingPrice, weiFinalPrice);
        uint min = Math.min(weiStartingPrice, weiFinalPrice);
        uint diff = max.sub(min);
        PriceDirection direction = PriceDirection.DOWN;
        if (max == weiFinalPrice) {
            direction = PriceDirection.UP;
        }
        return (diff.div(totalPriceChangePeriod.mul(_numOfPriceChangesPerHour)), direction);
    }

    function withdraw(uint tokenId) public virtual override onlyHolder(tokenId) {
        delete _priceSettings[tokenId];
        super.withdraw(tokenId);
    }
}