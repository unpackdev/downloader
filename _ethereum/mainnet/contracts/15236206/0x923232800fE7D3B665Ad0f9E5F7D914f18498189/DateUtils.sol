// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DateUtils {
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant SECONDS_IN_DAY = 86400;
    uint256 constant SECONDS_IN_YEAR = 31536000;
    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;
    uint16 constant ORIGIN_YEAR = 1970;
    uint256 constant SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR = 126230400;
    uint256 constant SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999 = 883612800;
    uint256 constant SECONDS_IN_100_YEARS = 3155673600;
    uint256 constant SECONDS_IN_400_YEARS = 12622780800;

    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) private pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isDateValid(
        uint16 year,
        uint16 month,
        uint16 day
    ) internal view returns (bool) {
        return day > 0 && getDaysInMonth(month, year) >= day;
    }

    function getDaysInMonth(uint16 month, uint16 year)
        internal
        pure
        returns (uint16)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function getDayFromTimestamp(uint256 timestamp)
        internal
        view
        returns (uint16)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;
        uint16 year;
        uint16 month;
        uint16 day;

        // Year
        year = getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(month, year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        return day;
    }

    /**
    @dev Convert timestamp to YMD (year, month, day)
    @param _dt Date as timestamp integer
    @return secondsRemaining
   */
    function getUTCSecondsOffsetInDay(uint256 _dt)
        internal
        pure
        returns (uint256 secondsRemaining)
    {
        uint16 year;
        uint8 month;
        uint8 day;
        secondsRemaining = _dt;
        (secondsRemaining, year) = getYearAndSecondsRemaining(secondsRemaining);
        (secondsRemaining, month) = getMonth(secondsRemaining, year);
        (secondsRemaining, day) = getDay(secondsRemaining);
        return secondsRemaining;
    }

    // functions to calculate year, month, or day from timestamp
    function getYearAndSecondsRemaining(uint256 _secondsRemaining)
        private
        pure
        returns (uint256 secondsRemaining, uint16 year)
    {
        uint256 res;
        uint32 secondsInThisYear;

        secondsRemaining = _secondsRemaining;
        year = 1970;

        if (secondsRemaining < (2 * SECONDS_IN_YEAR)) {
            res = secondsRemaining / SECONDS_IN_YEAR;
            secondsRemaining -= res * SECONDS_IN_YEAR;
            year += uint16(res);
        } else {
            secondsRemaining -= 2 * SECONDS_IN_YEAR;
            year = 1972;

            if (
                secondsRemaining >= SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999
            ) {
                secondsRemaining -= SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999;
                year += 28;

                res = secondsRemaining / SECONDS_IN_400_YEARS;
                secondsRemaining -= res * SECONDS_IN_400_YEARS;
                year += uint16(res * 400);

                secondsInThisYear = uint32(getSecondsInYear(year));

                if (secondsRemaining >= secondsInThisYear) {
                    secondsRemaining -= secondsInThisYear;
                    year += 1;
                }

                if (!isLeapYear(year)) {
                    res = secondsRemaining / SECONDS_IN_100_YEARS;
                    secondsRemaining -= res * SECONDS_IN_100_YEARS;
                    year += uint16(res * 100);
                }
            }

            res = secondsRemaining / SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR;
            secondsRemaining -= res * SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR;
            year += uint16(res * 4);

            secondsInThisYear = uint32(getSecondsInYear(year));

            if (secondsRemaining >= secondsInThisYear) {
                secondsRemaining -= secondsInThisYear;
                year += 1;
            }

            if (!isLeapYear(year)) {
                res = secondsRemaining / SECONDS_IN_YEAR;
                secondsRemaining -= res * SECONDS_IN_YEAR;
                year += uint16(res);
            }
        }
    }

    function getSecondsInYear(uint16 _year) private pure returns (uint256) {
        if (isLeapYear(_year)) {
            return (SECONDS_IN_YEAR + SECONDS_IN_DAY);
        } else {
            return SECONDS_IN_YEAR;
        }
    }

    function getYear(uint256 timestamp) private pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 _secondsRemaining, uint16 _year)
        private
        pure
        returns (uint256 secondsRemaining, uint8 month)
    {
        uint8[13] memory monthDayMap;
        uint32[13] memory monthSecondsMap;

        secondsRemaining = _secondsRemaining;

        if (isLeapYear(_year)) {
            monthDayMap = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            monthSecondsMap = [
                0,
                2678400,
                5184000,
                7862400,
                10454400,
                13132800,
                15724800,
                18403200,
                21081600,
                23673600,
                26352000,
                28944000,
                31622400
            ];
        } else {
            monthDayMap = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            monthSecondsMap = [
                0,
                2678400,
                5097600,
                7776000,
                10368000,
                13046400,
                15638400,
                18316800,
                20995200,
                23587200,
                26265600,
                28857600,
                31536000
            ];
        }

        for (uint8 i = 1; i < 13; i++) {
            if (secondsRemaining < monthSecondsMap[i]) {
                month = i;
                secondsRemaining -= monthSecondsMap[i - 1];
                break;
            }
        }
    }

    function getDay(uint256 _secondsRemaining)
        private
        pure
        returns (uint256 secondsRemaining, uint8 day)
    {
        uint256 res;

        secondsRemaining = _secondsRemaining;

        res = secondsRemaining / SECONDS_IN_DAY;
        secondsRemaining -= res * SECONDS_IN_DAY;
        day = uint8(res + 1);
    }

    function getDayIndexInYear(uint16 year, uint16 month, uint256 day)
        internal
        pure
        returns (uint256 index) 
    {
        index = 0;
        for (uint16 i = 1; i < month; i++) { 
            index += getDaysInMonth(i, year);
        }
        index += day - 1;
    }
}
