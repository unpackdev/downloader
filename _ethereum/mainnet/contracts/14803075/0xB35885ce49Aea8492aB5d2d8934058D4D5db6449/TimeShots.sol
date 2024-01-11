// SPDX-License-Identifier: MIT
// Created by 0xTimes.eth

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract TimeShots is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    event Mint(uint256 tokenId, address ownder, uint value);

    struct TimeShotsObject {
        uint256 tokenId;
        uint256 dashLength;
        uint256 dashSpacing;
        uint256 tintColor;
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 mSeconds;
        uint256[12] bitSeconds;
    }

    string[3] private colorTraits = ['White', 'Gold', 'Ruby'];
    string[3] private tintColors = ['#ffffff', '#ff7f00', '#CC0033'];
    string[12] private ones = [
        '<path d="M402 640 v50" fill="none" stroke="',
        '<path d="M422 640 v50" fill="none" stroke="',
        '<path d="M442 640 v50" fill="none" stroke="',
        '<path d="M462 640 v50" fill="none" stroke="',
        '<path d="M482 640 v50" fill="none" stroke="',
        '<path d="M502 640 v50" fill="none" stroke="',
        '<path d="M522 640 v50" fill="none" stroke="',
        '<path d="M542 640 v50" fill="none" stroke="',
        '<path d="M562 640 v50" fill="none" stroke="',
        '<path d="M582 640 v50" fill="none" stroke="',
        '<path d="M602 640 v50" fill="none" stroke="',
        '<path d="M622 640 v50" fill="none" stroke="'
        ];
    string[12] private zeros = [
        '<path d="M402,650 v30" fill="none" stroke="',
        '<path d="M422,650 v30" fill="none" stroke="',
        '<path d="M442,650 v30" fill="none" stroke="',
        '<path d="M462,650 v30" fill="none" stroke="',
        '<path d="M482,650 v30" fill="none" stroke="',
        '<path d="M502,650 v30" fill="none" stroke="',
        '<path d="M522,650 v30" fill="none" stroke="',
        '<path d="M542,650 v30" fill="none" stroke="',
        '<path d="M562,650 v30" fill="none" stroke="',
        '<path d="M582,650 v30" fill="none" stroke="',
        '<path d="M602,650 v30" fill="none" stroke="',
        '<path d="M622,650 v30" fill="none" stroke="'
        ];

    mapping(uint256 => uint256) private _tokenPrice;

    constructor() ERC721("TimeShots", "TIME") {
        for (uint256 i = 0; i < 3; i ++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _tokenPrice[tokenId] = 0;
            _safeMint(_msgSender(), tokenId);
        }
    }

    function mint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _tokenPrice[tokenId] = msg.value;
        _safeMint(_msgSender(), tokenId);

        emit Mint(tokenId, msg.sender, msg.value);
    }

    function _snapshotObject(uint256 tokenId, uint256 amount) internal view returns (TimeShotsObject memory) {
        if (tokenId == 0) {
            return TimeShotsObject(0,1,2,0,0,0,0,0,0,[uint256(0),0,0,0,0,0,0,0,0,0,0,0]);
        } else if (tokenId == 1) {
            return TimeShotsObject(1,1,2,1,0,0,0,0,0,[uint256(0),0,0,0,0,0,0,0,0,0,0,0]);
        } else if (tokenId == 2) {
            return TimeShotsObject(2,1,2,2,0,0,0,0,0,[uint256(0),0,0,0,0,0,0,0,0,0,0,0]);
        }
        
        TimeShotsObject memory timeShot;
        uint256 timestamp = block.timestamp;
        DateTime._DateTime memory datetime = DateTime.parseTimestamp(timestamp);

        uint256 randA = random(string(abi.encodePacked("Dash Length", toString(amount), toString(block.number), toString(block.difficulty), toString(timestamp % 525), toString(tokenId))));

        uint256 rn1 = randA % 314;

        if (rn1 == 0) {
            rn1 = 1;
        }
        
        uint256 randB = random(string(abi.encodePacked("Dash Spacing", toString(randA), toString(timestamp % 4199), toString(block.gaslimit), toString(block.number), toString(tokenId))));

        uint256 rn2 = randB % (314 - rn1);
        if (rn2 == 0) {
            rn2 = 1;
        }

        timeShot.tokenId = tokenId;
        timeShot.dashLength = rn1;
        timeShot.dashSpacing = rn2;
        if ((timestamp % 60 == 0) || amount >= 0.5 ether) {
            timeShot.tintColor = 2;
        } else if (amount >= 0.1 ether) {
            timeShot.tintColor = 1;
        } else {
            timeShot.tintColor = 0;
        }
        timeShot.year = datetime.year;
        timeShot.month = datetime.month;
        timeShot.day = datetime.day;
        timeShot.hour = datetime.hour;
        timeShot.mSeconds = timestamp % 3600;
        timeShot.bitSeconds = toBinary(timeShot.mSeconds);

        return timeShot;
    }

    function _getSVG(TimeShotsObject memory timeShot) internal view returns (string memory) {
        string[23] memory parts;

        parts[0] = '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg"><path fill="#000000" d="M0 0h1024v1024H0z"/>';
        parts[1] = '<ellipse opacity="0.2" rx="100" ry="100" cx="512" cy="320" stroke="#ffffff" fill="none"/>';
        parts[2] = '<ellipse rx="100" ry="100" cx="512" cy="320" stroke-dasharray="';
        parts[3] = toString(timeShot.dashLength);
        parts[4] = ",";
        parts[5] = toString(timeShot.dashSpacing);
        parts[6] = '" stroke="';
        parts[7] = tintColors[timeShot.tintColor];
        parts[8] ='" fill="none"/>';
        parts[9] = '<text opacity="0.65" fill="none" style="font-size:40pt; font-family: Futura Condensed ExtraBold, Arial Black, sans-serif; dominant-baseline:middle; text-anchor:middle;" x="512" y="512" stroke="';
        parts[10] = tintColors[timeShot.tintColor];
        parts[11] = '" >';
        parts[12] = toString(timeShot.year);
        parts[13] = '-';
        parts[14] = toString(timeShot.month);
        parts[15] = '-';
        parts[16] = toString(timeShot.day);
        parts[17] = '</text>';
        parts[18] = '<text opacity="0.65" fill="none" style="font-size:40pt; font-family: Futura Condensed ExtraBold, Arial Black, sans-serif; dominant-baseline:middle; text-anchor:middle;" x="512" y="580" stroke="';
        parts[19] = tintColors[timeShot.tintColor];
        parts[20] = '" >';
        parts[21] = toString(timeShot.hour);
        parts[22] = 'H</text>';

        string[13] memory lines;

        for (uint256 i = 0; i < 12; i++) {
            if (timeShot.bitSeconds[i] == 1) {
                lines[i] = string(abi.encodePacked(ones[i], tintColors[timeShot.tintColor], '"/>'));
            } else {
                lines[i] = string(abi.encodePacked(zeros[i], tintColors[timeShot.tintColor], '"/>'));
            }            
        }

        lines[12] = '</svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8],parts[9],parts[10]));
                      output = string(abi.encodePacked(output, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18]));
                      output = string(abi.encodePacked(output, parts[19], parts[20], parts[21],parts[22]));
                      output = string(abi.encodePacked(output, lines[0], lines[1], lines[2], lines[3], lines[4], lines[5], lines[6]));
                      output = string(abi.encodePacked(output, lines[7], lines[8], lines[9], lines[10], lines[11], lines[12]));

        return output;
    }

    function _getTraits(TimeShotsObject memory timeShot) internal view returns (string memory) {
        
        string[14] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Year","value": "';
        parts[1] = toString(timeShot.year);
        parts[2] = '"}, {"trait_type": "Month","value": "';
        parts[3] = toString(timeShot.month);
        parts[4] = '"}, {"trait_type": "Day","value": "';
        parts[5] = toString(timeShot.day);
        parts[6] = '"}, {"trait_type": "Hour","value": "';
        parts[7] = toString(timeShot.hour);
        if (timeShot.mSeconds == 0) {
            parts[8] = 'H"}, {"trait_type": "OClock","value": "true';
        } else {
            parts[8] = 'H"}, {"trait_type": "OClock","value": "false';
        }
        parts[9] = '"}, {"trait_type": "Color","value": "';
        parts[10] = colorTraits[timeShot.tintColor];
        parts[11] = '"}, {"trait_type": "MS","value": ';
        parts[12] = toString(timeShot.mSeconds);
        parts[13] = '}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13]));
        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        TimeShotsObject memory timeShot = _snapshotObject(tokenId, _tokenPrice[tokenId]);
        string memory json = Base64.encode(bytes(string(
            abi.encodePacked(
                '{"name": "TIME #', 
                toString(timeShot.tokenId), 
                '", "description": "Make snapshots for the on-chain past time. The artwork and metadata are fully on-chain and were randomly generated at mint."', 
                _getTraits(timeShot), 
                '"image": "data:image/svg+xml;base64,', 
                Base64.encode(bytes(_getSVG(timeShot))), 
                '"}'
                )
            )
        ));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function toBinary(uint256 secs) internal pure returns(uint256[12] memory output) {
        require(secs < 4096, "Fatal error.");

        for (uint256 i = 0; i < 12; i ++) {
            if (secs % 2 == 1) {
                output[11 - i] = 1;
            } else {
                output[11 - i] = 0;
            }
            secs /= 2;
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    receive () external payable {}

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function finalize() public onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
        selfdestruct(payable(_msgSender()));
    }

}

library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
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

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}