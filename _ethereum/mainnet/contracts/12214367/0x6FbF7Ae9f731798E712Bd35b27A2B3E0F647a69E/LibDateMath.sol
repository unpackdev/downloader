pragma solidity ^0.7.5;

import "./LibString.sol";

library LibDateMath  {
    /*
    *  Date and Time utilities for ethereum contracts
    *
    */
    using LibString for string;

    struct _DateTime {
        int256 year;
        uint month;
        uint day;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    int256 constant ORIGIN_YEAR = 1970;

    function getDateAsString(int256 timestamp) internal pure returns (string memory) {
        _DateTime memory dt = parseTimestamp(timestamp);

        string memory monthStr;
        string memory dayStr;
        if (dt.month < 10) {
            monthStr = LibString.strConcat("0", uint2str(dt.month));
        } else {
            monthStr = uint2str(dt.month);
        }
        if (dt.day < 10) {
            dayStr = LibString.strConcat("0", uint2str(dt.day));
        } else {
            dayStr = uint2str(dt.day);
        }
        return LibString.strConcat(LibString.strConcat(monthStr, "/", dayStr, "/"), int2str(dt.year));
    }

    function isLeapYear(int256 year) public pure returns (bool) {
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

    function leapYearsBefore(int256 year) internal pure returns (uint) {
        year -= 1;
        return uint(year / 4 - year / 100 + year / 400);
    }

    function getDaysInMonth(uint month, int256 year) internal pure returns (uint) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        else if (isLeapYear(int256(year))) {
            return 29;
        }
        else {
            return 28;
        }
    }

    function parseTimestamp(int256 timestamp) internal pure returns (_DateTime memory) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint i;
        _DateTime memory dt;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * uint((dt.year - ORIGIN_YEAR - int256(buf)));

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, int256(dt.year));
            if (int256(secondsInMonth + secondsAccountedFor) > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, int256(dt.year)); i++) {
            if (int256(DAY_IN_SECONDS + secondsAccountedFor) > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        return dt;
    }

    function getYear(int256 timestamp) internal pure returns (int256) {
        uint secondsAccountedFor = 0;
        int256 year;
        uint numLeapYears;

        // Year
        year = int256(ORIGIN_YEAR) + timestamp / int256(YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * uint((year - ORIGIN_YEAR - int256(numLeapYears)));

        while (int256(secondsAccountedFor) > timestamp) {
            if (isLeapYear(int256(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function int2str(int x) internal pure returns (string memory) {
        if (x < 0) {
            return LibString.strConcat("-", uint2str(uint(x * -1)));
        }
        return uint2str(uint(x));
    }
}