// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./DateTime.sol";

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are based on chars arithmetics
// and the results are used solely for display purposes (generating a token SYMBOL).
// Moreover - input data is provided only by contract owners, as creation of tokens is limited to owner only.
library GenSymbol {
    function monthToHex(uint8 m) public pure returns (bytes1) {
        if (m > 0 && m < 10) {
            return bytes1(uint8(bytes1("0")) + m);
        } else if (m >= 10 && m < 13) {
            return bytes1(uint8(bytes1("A")) + (m - 10));
        }
        revert("Invalid month");
    }

    function tsToDate(uint256 _ts) public pure returns (string memory) {
        bytes memory date = new bytes(4);

        uint256 year = DateTime.getYear(_ts);

        require(year >= 2020, "Year cannot be before 2020 as it is coded only by one digit");
        require(year < 2030, "Year cannot be after 2029 as it is coded only by one digit");

        date[0] = bytes1(
            uint8(bytes1("0")) + uint8(year - 2020) // 2020 is coded as "0"
        );

        date[1] = monthToHex(DateTime.getMonth(_ts)); // October = 10 is coded by "A"

        uint8 day = DateTime.getDay(_ts); // Day is just coded as a day of month starting from 1
        require(day > 0 && day <= 31, "Invalid day");

        date[2] = bytes1(uint8(bytes1("0")) + (day / 10));
        date[3] = bytes1(uint8(bytes1("0")) + (day % 10));

        return string(date);
    }

    function RKMconvert(uint256 _num) public pure returns (bytes memory) {
        bytes memory map = "0000KKKMMMGGGTTTPPPEEEZZZYYY";
        uint8 len;

        uint256 i = _num;
        while (i != 0) {
            // Calculate the length of the input number
            len++;
            i /= 10;
        }

        bytes1 prefix = map[len]; // Get the prefix code letter

        uint8 prefixPos = len > 3 ? ((len - 1) % 3) + 1 : 0; // Position of prefix (or 0 if the number is 3 digits or less)

        // Get the leftmost 4 digits from input number or just take the number as is if its already 4 digits or less
        uint256 firstFour = len > 4 ? _num / 10**(len - 4) : _num;

        bytes memory bStr = "00000";
        // We start from index 4 ^ of zero-string and go left
        uint8 index = 4;

        while (firstFour != 0) {
            // If index is on prefix position - insert a prefix and decrease index
            if (index == prefixPos) bStr[index--] = prefix;
            bStr[index--] = bytes1(uint8(48 + (firstFour % 10)));
            firstFour /= 10;
        }
        return bStr;
    }

    function uint2str(uint256 _num) public pure returns (bytes memory) {
        if (_num > 99999) return RKMconvert(_num);

        if (_num == 0) {
            return "00000";
        }
        uint256 j = _num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bStr = "00000";
        uint256 k = 4;
        while (_num != 0) {
            bStr[k--] = bytes1(uint8(48 + (_num % 10)));
            _num /= 10;
        }
        return bStr;
    }

    function genOptionSymbol(
        uint256 _ts,
        string memory _type,
        bool put,
        uint256 _strikePrice
    ) external pure returns (string memory) {
        string memory putCall;
        putCall = put ? "P" : "C";
        return string(abi.encodePacked(_type, tsToDate(_ts), putCall, uint2str(_strikePrice)));
    }
}
