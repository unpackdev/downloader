// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 private constant OFFSET19700101 = 2440588;

    function isLeapYear(uint256 year_) internal pure returns (bool leapYear) {
        leapYear =
            ((year_ % 4 == 0) && (year_ % 100 != 0)) ||
            (year_ % 400 == 0);
    }

    function getDaysInMonth(uint256 year_, uint256 month_)
        internal
        pure
        returns (uint256)
    {
        if (
            month_ == 1 ||
            month_ == 3 ||
            month_ == 5 ||
            month_ == 7 ||
            month_ == 8 ||
            month_ == 10 ||
            month_ == 12
        ) {
            return 31;
        } else if (month_ != 2) {
            return 30;
        } else {
            return isLeapYear(year_) ? 29 : 28;
        }
    }

    function isValidDate(
        uint256 year_,
        uint256 month_,
        uint256 day_
    ) internal pure returns (bool) {
        if (month_ > 0 && month_ <= 12) {
            uint256 daysInMonth = getDaysInMonth(year_, month_);
            if (day_ > 0 && day_ <= daysInMonth) {
                return true;
            }
        }
        return false;
    }

    function timestampFromDate(
        uint256 year_,
        uint256 month_,
        uint256 day_
    ) internal pure returns (uint256) {
        require(year_ >= 1970);
        int256 year = int256(year_);
        int256 month = int256(month_);
        int256 day = int256(day_);

        int256 totalDays = day -
            32075 +
            (1461 * (year + 4800 + (month - 14) / 12)) /
            4 +
            (367 * (month - 2 - ((month - 14) / 12) * 12)) /
            12 -
            (3 * ((year + 4900 + (month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        return uint256(totalDays) * SECONDS_PER_DAY;
    }
}
