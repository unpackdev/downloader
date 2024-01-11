// SPDX-License-Identifier: GPL-3.0

/// @title The SZNouns DAO auction house

/********************************************************************************
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@               @@@@@@@@@@@@@@               @@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@     \\\\@@@@@      @@@@@@@@@     \\\\@@@@      @@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@     \\\\\\@@@@@@@     @@@@@@     \\\\\\@@@@@@@     @@@@@@@@@@@@@@@@@ *
 * @@@@@@     \\\\\\\@@@@@@@@              \\\\\\\@@@@@@@@                  @@@ *
 * @@@@@@    \\\\\\\\@@@@@@@@@    @@@@    \\\\\\\\@@@@@@@@@    @@@@@@@@     @@@ *
 * @@@@@@@    \\\\\\\@@@@@@@@     @@@@     \\\\\\\@@@@@@@@     @@@@@@@@     @@@ *
 * @@@@@@@@    \\\\\\@@@@@@@     @@@@@@     \\\\\\@@@@@@@     @@@@@@@@@     @@@ *
 * @@@@@@@@@      \\\@@@@      @@@@@@@@@@      \\\@@@@      @@@@@@@@@@@     @@@ *
 * @@@@@@@@@@@@              @@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *
 ********************************************************************************/

// LICENSE
// SZNounsAuctionHouse.sol is a modified version NounsAuctionHouse.sol, which is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by szNounders DAO.

pragma solidity ^0.8.6;

import "./NounsAuctionHouse.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

contract SZNounsAuctionHouse is NounsAuctionHouse {
    enum SZN {
        WINTER,
        SPRING,
        SUMMER,
        FALL
    }

    uint256 constant DEFAULT_WINTER_DURATION = 24 hours;
    uint256 constant DEFAULT_FALL_SPRING_DURATION = 12 hours;
    uint256 constant DEFAULT_SUMMER_DURATION = 6 hours;

    // Length of 4, indices corresponding to int cast of enum value.
    uint256[4] durations;

    function getSzn() public view returns (SZN) {
        uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);

        // evenly distributing seasons throughout the calendar year
        if (month < 3) {
            return SZN.WINTER;
        }
        if (month < 6) {
            return SZN.SPRING;
        }
        if (month < 9) {
            return SZN.SUMMER;
        }
        if (month < 12) {
            return SZN.FALL;
        }
        // December is winter.
        return SZN.WINTER;
    }

    function getSznDuration(SZN szn) public view returns (uint256) {
        uint256 duration = durations[uint256(szn)];
        if (duration != 0) {
            return duration;
        }
        return getDefaultDuration(szn);
    }

    function setDuration(SZN szn, uint256 duration) external onlyOwner {
        durations[uint256(szn)] = duration;
    }

    function getDefaultDuration(SZN szn) public pure returns (uint256) {
        if (szn == SZN.WINTER) {
            return DEFAULT_WINTER_DURATION;
        }
        if (szn == SZN.SUMMER) {
            return DEFAULT_SUMMER_DURATION;
        }
        // szn is SZN.FALL or SZN.SPRING
        return DEFAULT_FALL_SPRING_DURATION;
    }

    function getDuration() public view override returns (uint256) {
        return getSznDuration(getSzn());
    }
}
