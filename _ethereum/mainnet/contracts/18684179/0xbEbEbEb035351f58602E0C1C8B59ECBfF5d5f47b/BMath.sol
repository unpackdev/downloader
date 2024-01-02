// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library BMath {

    uint16 internal constant HUNDRED_PERCENT = 10000;

    function getPercentage(uint256 value, uint16 percent) internal pure returns (uint256){
        if (percent >= HUNDRED_PERCENT){
            return value;
        }
        return value * percent / HUNDRED_PERCENT;
    }

    function getInvertedPercentage(uint256 value, uint16 percent) internal pure returns (uint256){
        if (percent >= HUNDRED_PERCENT){
            return value;
        }
        return value * HUNDRED_PERCENT / percent;
    }

}