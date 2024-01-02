// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "IBoostCalculator.sol";

contract DynamicBoostDelegate {
    address public boostDelegate;
    IBoostCalculator public immutable boostCalculator;

    constructor(IBoostCalculator _boostCalculator) {
        boostDelegate = msg.sender;
        boostCalculator = _boostCalculator;
    }

    function getFeePct(
        address,
        address,
        uint amount,
        uint previousAmount,
        uint totalWeeklyEmissions
    ) external view returns (uint256 feePct) {
        (uint256 maxBoostable, ) = boostCalculator.getClaimableWithBoost(boostDelegate, 0, totalWeeklyEmissions);

        // claim does not deplete 2x boost
        if (amount + previousAmount <= maxBoostable) {
            // if claim consumes >25% of boost, dynamic fee from 14-14.9%
            if (amount > maxBoostable / 4) {
                uint256 boostPct = (amount * 10000) / maxBoostable;
                return 1400 + ((90 * boostPct) / 10000);
            }
            // otherwise fee at 13.99%
            return 1399;
        }

        uint256 adjustedAmount = boostCalculator.getBoostedAmount(
            boostDelegate,
            amount,
            previousAmount,
            totalWeeklyEmissions
        );

        if ((previousAmount * 10000) / maxBoostable < 8000) {
            // if over 20% of 2x boost remains and the claim receives boost
            // of <1.9x, reject with 100% fee and wait for a small claim
            if (adjustedAmount < (amount * 9500) / 10000) return 10000;
        }

        // 1.7x boost (charged by convex and yearn)
        uint256 boostFloor = (amount * 8500) / 10000;

        // claim receives less than 1.7x boost
        if (adjustedAmount <= boostFloor) {
            // boost prior to claim is >1.8x, reject with 100% fee and wait for smaller claim
            if (previousAmount < (maxBoostable * 12) / 10) return 10000;
            // boost will be below 1.7x, fee at 0.01%
            else return 1;
        }

        // dynamic fee so boost after fee is ~1% above 1.7x
        return ((adjustedAmount - boostFloor) * 9900) / adjustedAmount;
    }

    function delegatedBoostCallback(address, address, uint, uint, uint, uint, uint) external pure returns (bool) {
        return true;
    }
}
