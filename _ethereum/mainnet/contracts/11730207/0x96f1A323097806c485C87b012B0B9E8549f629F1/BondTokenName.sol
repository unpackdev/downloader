pragma solidity 0.6.6;

// File: contracts/bondTokenName/BondTokenNameInterface.sol



/**
 * @title bond token name contract interface
 */
interface BondTokenNameInterface {
    function genBondTokenName(
        string calldata shortNamePrefix,
        string calldata longNamePrefix,
        uint256 maturity,
        uint256 solidStrikePriceE4
    ) external pure returns (string memory shortName, string memory longName);

    function getBondTokenName(
        uint256 maturity,
        uint256 solidStrikePriceE4,
        uint256 rateLBTWorthlessE4
    ) external pure returns (string memory shortName, string memory longName);
}

// File: @openzeppelin/contracts/utils/Strings.sol



/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/util/Digits.sol



library Digits {
    /**
     * @notice represent given number to `digits` digits string
     */
    function toString(uint256 value, uint256 digits)
        internal
        pure
        returns (string memory)
    {
        // solium-disable-previous-line security/no-assign-params
        bytes memory buffer = new bytes(digits);
        while (digits != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/util/DateTimeLibrary.sol



library DateTimeLibrary {
    uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 internal constant SECONDS_PER_HOUR = 60 * 60;
    uint256 internal constant SECONDS_PER_MINUTE = 60;
    int256 internal constant OFFSET19700101 = 2440588;

    uint256 internal constant DOW_MON = 1;
    uint256 internal constant DOW_TUE = 2;
    uint256 internal constant DOW_WED = 3;
    uint256 internal constant DOW_THU = 4;
    uint256 internal constant DOW_FRI = 5;
    uint256 internal constant DOW_SAT = 6;
    uint256 internal constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970, "year must be more than or equal to 1970");
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
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
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        uint256 year;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        uint256 year;
        uint256 month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    // function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
    //     uint year;
    //     uint month;
    //     uint day;
    //     (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     year += _years;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp >= timestamp);
    // }
    // function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
    //     uint year;
    //     uint month;
    //     uint day;
    //     (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     month += _months;
    //     year += (month - 1) / 12;
    //     month = (month - 1) % 12 + 1;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp >= timestamp);
    // }
    // function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    //     require(newTimestamp >= timestamp);
    // }
    // function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    //     require(newTimestamp >= timestamp);
    // }
    // function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    //     require(newTimestamp >= timestamp);
    // }
    // function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp + _seconds;
    //     require(newTimestamp >= timestamp);
    // }

    // function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
    //     uint year;
    //     uint month;
    //     uint day;
    //     (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     year -= _years;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }
    // function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
    //     uint year;
    //     uint month;
    //     uint day;
    //     (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    //     uint yearMonth = year * 12 + (month - 1) - _months;
    //     year = yearMonth / 12;
    //     month = yearMonth % 12 + 1;
    //     uint daysInMonth = _getDaysInMonth(year, month);
    //     if (day > daysInMonth) {
    //         day = daysInMonth;
    //     }
    //     newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }
    // function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    //     require(newTimestamp <= timestamp);
    // }
    // function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    //     require(newTimestamp <= timestamp);
    // }
    // function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    //     require(newTimestamp <= timestamp);
    // }
    // function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
    //     newTimestamp = timestamp - _seconds;
    //     require(newTimestamp <= timestamp);
    // }

    // function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
    //     require(fromTimestamp <= toTimestamp);
    //     uint fromYear;
    //     uint fromMonth;
    //     uint fromDay;
    //     uint toYear;
    //     uint toMonth;
    //     uint toDay;
    //     (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    //     (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    //     _years = toYear - fromYear;
    // }
    // function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
    //     require(fromTimestamp <= toTimestamp);
    //     uint fromYear;
    //     uint fromMonth;
    //     uint fromDay;
    //     uint toYear;
    //     uint toMonth;
    //     uint toDay;
    //     (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    //     (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    //     _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    // }
    // function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
    //     require(fromTimestamp <= toTimestamp);
    //     _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    // }
    // function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
    //     require(fromTimestamp <= toTimestamp);
    //     _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    // }
    // function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
    //     require(fromTimestamp <= toTimestamp);
    //     _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    // }
    // function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
    //     require(fromTimestamp <= toTimestamp);
    //     _seconds = toTimestamp - fromTimestamp;
    // }
}

// File: contracts/bondTokenName/BondTokenName.sol







/**
 * @title bond token name contract
 * @notice generate the name of bond token from its bond property
 */
contract BondTokenName is BondTokenNameInterface {
    using Strings for uint256;
    using Digits for uint256;
    using DateTimeLibrary for uint256;

    /**
     * @notice generate a bond token name with exactly 12 letters and a long bond token name
     */
    function genBondTokenName(
        string memory shortNamePrefix,
        string memory longNamePrefix,
        uint256 maturity,
        uint256 solidStrikePriceE0
    )
        public
        pure
        override
        returns (string memory shortName, string memory longName)
    {
        (uint256 year, uint256 month, uint256 day) = maturity.timestampToDate();
        string memory yearStr = year.toString(4);
        string memory monthStr = month.toString(2);
        string memory dayStr = day.toString(2);
        {
            string memory shortDateStr = string(
                abi.encodePacked(monthStr, dayStr)
            );
            string memory shortStrikePriceStr = solidStrikePriceE0.toString(4);

            shortName = string(
                abi.encodePacked(
                    shortNamePrefix,
                    shortDateStr,
                    "",
                    shortStrikePriceStr
                )
            );
        }
        {
            string memory dateStr = string(
                abi.encodePacked(yearStr, monthStr, dayStr)
            );
            string memory strikePriceStr = solidStrikePriceE0.toString();
            longName = string(
                abi.encodePacked(
                    longNamePrefix,
                    " ",
                    dateStr,
                    " ",
                    strikePriceStr
                )
            );
        }
    }

    function getBondTokenName(
        uint256 maturity,
        uint256 solidStrikePriceE0,
        uint256 rateLBTWorthlessE0
    )
        public
        pure
        override
        returns (string memory shortName, string memory longName)
    {
        if (solidStrikePriceE0 != 0) {
            return genBondTokenName("SBT", "SBT", maturity, solidStrikePriceE0);
        } else if (rateLBTWorthlessE0 != 0) {
            return genBondTokenName("LBT", "LBT", maturity, rateLBTWorthlessE0);
        } else {
            return genBondTokenName("IMT", "Immortal Option", maturity, 0);
        }
    }
}