// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/**
 * @title  Utility library for the DymeSpace contract
 * @author The DymeSpace crew
 * @notice The DymeSpaceUtils library provides helper functions for the DymeSpace contract
 */
library DymeSpaceUtils {
    enum Era {
        BCE,
        CE
    }

    struct Date {
        Era era;
        uint256 year;
        uint256 month;
        uint256 day;
    }


    /**
     * @notice Calculates a token ID based on a date
     * @param  era - the era
     * @param  year - the year
     * @param  month - the month
     * @param  day - the day
     * @return the token ID representing the date
     */
    function calcTokenId(Era era, uint256 year, uint256 month, uint256 day) internal pure returns (uint256) {
        return year * 100000 + month * 1000 + day * 10 + uint256(era);
    }


    /**
     * @notice Converts a token ID to a date
     * @param  tokenId - the token ID
     * @return the date representing the token ID
     */
    function tokenIdToDate(uint256 tokenId) internal pure returns (Date memory) {
        return Date({
            era: tokenId % 10 == 0 ? Era.BCE : Era.CE,
            day: (tokenId / 10) % 100,
            month: (tokenId / 1000) % 100,
            year: tokenId / 100000
        });
    }


    /**
     * @notice Calculates the number of days in a month
     * @param  year - the year of the month
     * @param  month - the month
     * @return the number of days of the month
     */
    function daysInMonth(uint256 month, uint256 year) internal pure returns (uint256) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }

        if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }

        if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        }

        return 0;
    }


    /**
     * @notice Checks if a given year is a leap year
     * @param  year - the year
     * @return true if it is a leap year, false if not
     */
    function isLeapYear(uint256 year) internal pure returns (bool) {
        return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0)); // https://en.wikipedia.org/wiki/Gregorian_calendar
    }


    /**
     * @notice Checks if a given token ID is valid
     * @param  tokenId - the tokenID
     * @return true if it is a valid token ID, false if not
     */
    function isTokenId(uint256 tokenId) internal pure returns (bool) {
        DymeSpaceUtils.Date memory date = DymeSpaceUtils.tokenIdToDate(tokenId);
        return DymeSpaceUtils.isEra(date.era)
            && DymeSpaceUtils.isYear(date.year)
            && DymeSpaceUtils.isMonth(date.month)
            && DymeSpaceUtils.isDay(date.year, date.month, date.day);
    }
    

    /**
     * @notice Checks if a given era is valid
     * @param  era - the era
     * @return true if it is a valid era, false if not
     */
    function isEra(Era era) internal pure returns (bool) {
        uint256 _era = uint256(era);
        return _era == 1 || _era == 0;
    }


    /**
     * @notice Checks if a given year is valid
     * @param  year - the year
     * @return true if it is a valid year, false if not
     */
    function isYear(uint256 year) internal pure returns (bool) {
        return year <= 13800000000 && year != 0;
    }


    /**
     * @notice Checks if a given month is valid
     * @param  month - the month
     * @return true if it is a valid month, false if not
     */
    function isMonth(uint256 month) internal pure returns (bool) {
        return month >= 1 && month <= 12;
    }


    /**
     * @notice Checks if a given day is valid
     * @param  year - the year of the day
     * @param  month - the month of the day
     * @param  day - the day
     * @return true if it is a valid day, false if not
     */
    function isDay(uint256 year, uint256 month, uint256 day) internal pure returns (bool) {
        return day >= 1 && day <= DymeSpaceUtils.daysInMonth(month, year);
    }
}
