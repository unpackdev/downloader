// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Strings.sol";
import "SafeCast.sol";

/**
 * @title DateCalendar contract
 * 
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 */
contract DateCalendar is ERC721, Ownable {
    /**
     * @dev Emitted when `dateTokenIndex` token's `GCalDate` proof has been 
     * created and saved to the contract. This event will contain the
     * variables of the `GCalDate`, excluding `day_of_week`.
     */
    event DateProof(uint8 indexed day, 
                    uint8 indexed month, 
                    int256 indexed year);

    using Strings for uint256;
    using SafeCast for uint256;

    // Base URI for the Date Calendar contract
    string private _baseDCURI;

    // Flag indicating whether future dates can be minted.
    bool public allowFutureDates;

    // Midpoint value of the Date Token Index (DTI) range
    uint256 private constant _dtiMidpoint = 7305000000000;

    /**
     * @dev A Julian Date (JD) is composed
     * of two pieces, the Julian Day Number (JDN)
     * and day fraction. 
     * 
     * @param `jdn` describes the number of solar days
     * between the given day and a fixed day in history starting
     * from 12:00 UT (noon).
     * @param `dayFraction` is between 0 and 1,
     *`dayFraction` should be interpreted as the
     * number after the decimal point. I.e.
     * 5 means 0.5. 51 mean 0.51.
     */
    struct JulianDate {
        int256 jdn;
        uint16 dayFraction;
    }

    // Unix epoch date (1970-01-01) JD
    JulianDate private _unixEpochJD = JulianDate(2440587, 5);

    /**
     * @dev Representation of a Gregorian
     * calendar date.
     *
     * @param `day_of_week` from 0 to 6 indicating
     * the day of the week, with 0 being Sunday,
     * 1 being Monday, etc.
     * @param `day`: integer from 1 to 31 indicating the
     * day of the month.
     * @param `month` integer from 1 to 12 indicating the
     * month of the year.
     * @param `year` signed integer for the year. The year
     * before 1 is 0, and the year before 0 is -1, etc.
     * A year of 1 is 1 CE, a year of 0 is 1 BCE, 
     * a year of -1 is 2 BCE, etc.
     */
    struct GCalDate {
        uint8 day_of_week; 
        uint8 day;
        uint8 month;
        int256 year;
    }   

    // Mapping from DTI to Gregorian calendar date proof
    mapping(uint256 => GCalDate) private _dateProofs;

    /**
     * @dev Initialize the contract with a `name` and `symbol`.
     */
    constructor(string memory name, string memory symbol, bool allowFutureDates_) ERC721(name, symbol) { 
        allowFutureDates = allowFutureDates_;
    }

    /**
     * @dev Set the base URI for the contract. Token URIs are derived from this base.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseDCURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseDCURI;
    }

    /**
     * @dev Retrieve the Gregorian calendar date proof of a date token index.
     */
    function proofOf(uint256 dateTokenIndex) public view returns (GCalDate memory) {
        require(_exists(dateTokenIndex), "DateCalendar: date proof query for nonexistent token");

        return _dateProofs[dateTokenIndex];
    }

    /**
     * @dev Returns the number of days since the Unix epoch (1970-01-01).
     */
    function _daysFromUnixEpoch() private view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /**
     * @dev Determines the JD of the current block.
     */
     function currentBlockJD() public view returns (JulianDate memory) {
        int256 unixDelta = int256(_daysFromUnixEpoch());
        return JulianDate(_unixEpochJD.jdn + unixDelta, 5);
     }

    /**
     * @dev Convert a Date Token Index to a Julian Date.
     */
     function _dtiToJD(uint256 dateTokenIndex) private pure returns (JulianDate memory) {
        int256 jdn = int256(dateTokenIndex) - int256(_dtiMidpoint);
        return JulianDate(jdn, 5);
     }


    /**
     * @dev Determines whether a JD has been released.
     */
     function _isReleased(JulianDate memory julianDate) private view returns (bool) {
        if (allowFutureDates) {
            return true;
        }
        JulianDate memory currentJD = currentBlockJD();
        return julianDate.jdn <= currentJD.jdn;
         
     }


    /**
     * @dev Mint a date calendar token.
     */
    function mintDate(uint256 dateTokenIndex) public {
        JulianDate memory jd = _dtiToJD(dateTokenIndex);
        require(_isReleased(jd), "DateCalendar: date has not yet been released.");

        _safeMint(msg.sender, dateTokenIndex);
        _setDateProof(dateTokenIndex, jd);

    }

    /**
     * @dev Save the Gregorian calendar date proof for a given date token index.
     */
     function _setDateProof(uint256 dateTokenIndex, JulianDate memory julianDate) private {
        (uint8 dow, uint8 d, uint8 m, int256 y) = _jdToGCalDateVariables(julianDate);

        GCalDate storage date = _dateProofs[dateTokenIndex];
        date.day_of_week = dow;
        date.day = d;
        date.month = m;
        date.year = y;

        emit DateProof(d, m, y);
         
     }

    uint16[12] private _toGCalDateHelper = [0, 31, 61, 92, 122, 153, 184, 214, 245, 275, 306, 337];

    /**
     * @dev Calculate the variables of a Gregorian calendar date from a JD.
     *
     * References
     * [1] P. Baum, "Date Algorithms", 2020.
     * [2] J. Meeus, "Astronomical Algorithms", pp. 65, 1998. 
     */    
    function _jdToGCalDateVariables(JulianDate memory julianDate) private view returns (uint8, uint8, uint8, int256) {
        uint8 dow = _jdToDOW(julianDate);
        (uint8 d, uint8 m, int256 y) = _jdToDMY(julianDate);
        return (dow, d, m, y);

    }

    function _jdToDMY(JulianDate memory julianDate) private view returns (uint8, uint8, int256) {
        int256 z = julianDate.jdn - 1721118;
        int256 a_ = z * 100 - 25;
        int256 a = _divideAndFloor(a_, 3652425);
        int256 p1_ = _divideAndFloor(a,  4);
        int256 y_ = z * 100 - 25 + a * 100 - p1_ * 100;
        int256 y = _divideAndFloor(y_, 36525);
        int256 p2_ = _divideAndFloor(36525 * y, 100);
        uint256 c = uint256(z + a - p1_ - p2_);
        uint8 m = ((5 * c + 456) / 153).toUint8();
        uint16 f = _toGCalDateHelper[m-3];
        uint8 d = (c - f).toUint8();
        if (m > 12) {
            y += 1;
            m -= 12;
        }
        return (d, m, y);
    }

    function _jdToDOW(JulianDate memory julianDate) private view returns (uint8) {
        uint256 dow = uint256(_clockModulo(julianDate.jdn + 2, 7));
        return dow.toUint8();
    }

    /**
     * @dev Take the floor of (x / y). Assumes y > 0.
     */
    function _divideAndFloor(int256 x, int256 y) private pure returns (int256) {
        if (x >= 0) {
            // For positive division, floor is done by default.
            return x / y;
        } else {
            // For negative division, need to take the negative
            // of the ceiling of the positive division.
            return -((-x + y -1) / y);
        }

    }

    /**
     * @dev Modulo in solidity is a remainder. This returns the clock modulo
     * of (x % y). Assumes y > 0.
     */
    function _clockModulo(int256 x, int256 y) private pure returns (int256) {
        return x - (y * _divideAndFloor(x, y));
    }


}