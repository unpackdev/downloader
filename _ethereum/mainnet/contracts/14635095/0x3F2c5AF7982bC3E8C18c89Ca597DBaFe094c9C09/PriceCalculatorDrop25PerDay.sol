// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IPriceCalculator.sol";

contract PriceCalculatorDrop25PerDay is IPriceCalculator, Ownable {
    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 listedOn
    ) external view returns (uint256) {
        return _calculate(startingPrice, listedOn, block.timestamp);
    }

    function calculatePrice(
        uint256 startingPrice,
        uint256 listedOn,
        uint256 time
    ) external pure returns (uint256) {
        return _calculate(startingPrice, listedOn, time);
    }
    
    function isPriceAllowed(
        uint256 startingPrice
    ) external pure returns (bool) {
        (bool isSuccess,) = SafeMath.tryMul(startingPrice, 3);
        if (isSuccess == false) {
            return false;
        }

        uint256 nextDayPrice = startingPrice * 3 / 4;
        uint256 diff = startingPrice - nextDayPrice;
        (isSuccess,) = SafeMath.tryMul(diff, 86399);
        if (isSuccess == false) {
            return false;
        }

        return true;
    }

    function _calculate(
        uint256 startingPrice,
        uint256 listedOn,
        uint256 currentTime
    ) internal pure returns (uint256) {
        uint256 daysGone = (currentTime - listedOn) / 86400;
        uint256 currentPrice = startingPrice;
        for (uint256 index = 0; index < daysGone; index++) {
            currentPrice = currentPrice * 3 / 4;

            if (currentPrice == 0) {
                return 0;
            }
        }

        uint256 partInADay = (currentTime - listedOn) % 86400;
        if (partInADay != 0) {
            uint256 nextDayPrice = currentPrice * 3 / 4;
            uint256 partInADayPrice = (currentPrice - nextDayPrice) * partInADay / 86400;
            currentPrice = currentPrice - partInADayPrice; 
        }

        return currentPrice;
    }
}