pragma solidity 0.8.7;

import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title TimeHelpers
 * @dev The contract performs time operations.
 * 
 */
contract TimeHelpers {

    uint constant private _ZERO_YEAR = 2021;

    uint constant private _ZERO_MONTH = 1;

    uint constant private _ZERO_DAY = 11;

    function getCurrentMonth() external view virtual returns (uint) {
        return timestampToMonth(block.timestamp);
    }

    function timestampToDay(uint timestamp) external view returns (uint) {
        uint wholeDays = timestamp / BokkyPooBahsDateTimeLibrary.SECONDS_PER_DAY;
        uint zeroDay = BokkyPooBahsDateTimeLibrary.timestampFromDate(_ZERO_YEAR, _ZERO_MONTH, _ZERO_DAY) /
            BokkyPooBahsDateTimeLibrary.SECONDS_PER_DAY;
        require(wholeDays >= zeroDay, "Timestamp is too far in the past");
        return wholeDays - zeroDay;
    }

    function timestampToYear(uint timestamp) external view virtual returns (uint) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        require(
            year >= _ZERO_YEAR || month >= _ZERO_MONTH || day >= _ZERO_DAY,
            "Timestamp is too far in the past"
        );
        return year - _ZERO_YEAR;
    }

    function addDays(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addDays(fromTimestamp, n);
    }

    function addMonths(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addMonths(fromTimestamp, n);
    }

    function addYears(uint fromTimestamp, uint n) external pure returns (uint) {
        return BokkyPooBahsDateTimeLibrary.addYears(fromTimestamp, n);
    }

    function timestampToMonth(uint timestamp) public view virtual returns (uint) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        require(
            year >= _ZERO_YEAR || month >= _ZERO_MONTH || day >= _ZERO_DAY,
            "Timestamp is too far in the past"
        );
        month = month - (day < _ZERO_DAY ? 2 : 1) + (year - _ZERO_YEAR) * 12;
        require(month > 0, "Timestamp is too far in the past");
        return month;
    }

    function monthToTimestamp(uint month) public view virtual returns (uint timestamp) {
        uint year = _ZERO_YEAR;
        uint _month = month;
        year = year + _month / 12;
        _month = _month % 12;
        _month = _month + 1;
        return BokkyPooBahsDateTimeLibrary.timestampFromDate(year, _month, _ZERO_DAY);
    }
}
