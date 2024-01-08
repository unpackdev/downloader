// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

import "./Base64.sol";

contract D is ERC721, Ownable, ReentrancyGuard {
    using Strings for string;

    struct Date {
        uint16 year;
        uint8 month;
        uint8 day;
    }
    mapping(uint256 => Date) private id_to_Date;

    string[] private months = [
        "JANUARY",
        "FEBRUARY",
        "MARCH",
        "APRIL",
        "MAY",
        "JUNE",
        "JULY",
        "AUGUST",
        "SEPTEMBER",
        "OCTOBER",
        "NOVEMBER",
        "DECEMBER"
    ];

    constructor() ERC721("d", "D") {}

    function safeMint(
        uint16 year,
        uint8 month,
        uint8 day,
        address to
    ) public {
        uint256 _tokenId = id(year, month, day);
        require(!_exists(_tokenId), "D: date already claimed");
        id_to_Date[_tokenId] = Date(year, month, day);

        _safeMint(to, _tokenId);
    }

    function id(
        uint16 year,
        uint8 month,
        uint8 day
    ) internal pure returns (uint256) {
        require(1 <= day && day <= numDaysInMonth(month, year));
        return uint256(year) * 10000 + uint256(month) * 100 + uint256(day);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "D: URI query for nonexistent token");
        string[7] memory parts;

        Date memory date = id_to_Date[tokenId];

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: sans-serif; font-size: 28px; }</style><rect width="100%" height="100%" fill="black" /><text x="20" y="330" class="base">';
        parts[1] = Strings.toString(date.year);
        parts[2] = " ";
        parts[3] = months[date.month - 1];
        parts[4] = " ";
        parts[5] = Strings.toString(date.day);
        parts[6] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "D #',
                        Strings.toString(tokenId),
                        '", "description": "D is just a date.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '", "attributes": [{"trait_type": "Year", "value": ',
                        Strings.toString(date.year),
                        '}, {"trait_type": "Month", "value": ',
                        Strings.toString(date.month),
                        '}, {"trait_type": "Day", "value": ',
                        Strings.toString(date.day),
                        "}] }"
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function get(uint256 tokenId)
        external
        view
        returns (
            uint16 year,
            uint8 month,
            uint8 day
        )
    {
        require(_exists(tokenId), "D: token not minted");
        Date memory date = id_to_Date[tokenId];
        year = date.year;
        month = date.month;
        day = date.day;
    }

    function isLeapYear(uint16 year) public pure returns (bool) {
        require(1 <= year, "D: year must be bigger or equal 1");
        return (year % 4 == 0) && (year % 100 == 0) && (year % 400 == 0);
    }

    function numDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        require(1 <= month && month <= 12, "D: month must be between 1 and 12");
        require(1 <= year, "D: year must be bigger or equal 1");

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
        } else if (month == 2) {
            return isLeapYear(year) ? 29 : 28;
        } else {
            return 30;
        }
    }
}
