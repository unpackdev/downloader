// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Base64.sol";

import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract Stats is ERC721Enumerable, ReentrancyGuard {
    ERC721 public ogStrikers =
        ERC721(0xdCAad9Fd9a74144d226DbF94ce6162ca9f09ED7e);
    ERC721 public wrappedStrikers =
        ERC721(0x11739D7bd793543a6e83Bd7D8601fcbcDE04e798);

    string[] private countries = [
        unicode"🇧🇪",
        unicode"🇧🇷",
        unicode"🇫🇷",
        unicode"🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        unicode"🇮🇹",
        unicode"🇦🇷",
        unicode"🇪🇸",
        unicode"🇵🇹",
        unicode"🇲🇽",
        unicode"🇺🇸",
        unicode"🇩🇰",
        unicode"🇳🇱",
        unicode"🇺🇾",
        unicode"🇨🇭",
        unicode"🇨🇴",
        unicode"🇩🇪",
        unicode"🇸🇪",
        unicode"🇭🇷",
        unicode"🏴󠁧󠁢󠁷󠁬󠁳󠁿",
        unicode"🇨🇱",
        unicode"🇸🇳",
        unicode"🇵🇪",
        unicode"🇦🇹",
        unicode"󠁧󠁢󠁥󠁮🇯🇵",
        unicode"🇺🇦",
        unicode"🇮🇷",
        unicode"🇵🇱",
        unicode"🇹🇳",
        unicode"🇷🇸",
        unicode"🇩🇿",
        unicode"🇨🇿",
        unicode"🇲🇦",
        unicode"🇵🇾",
        unicode"󠁧󠁢󠁥󠁮🇳🇬",
        unicode"🇦🇺",
        unicode"🇰🇷",
        unicode"🇭🇺",
        unicode"🇸🇰",
        unicode"🇹🇷",
        unicode"🇻🇪",
        unicode"🇷🇺",
        unicode"🇶🇦",
        unicode"🇳🇴",
        unicode"🇨🇷",
        unicode"🇷🇴",
        unicode"🇪🇬",
        unicode"🇮🇪",
        unicode"🇬🇷",
        unicode"🏴󠁧󠁢󠁳󠁣󠁴󠁿",
        unicode"🇯🇲",
        unicode"🇬🇭",
        unicode"🇮🇸",
        unicode"🇨🇲",
        unicode"🇪🇨",
        unicode"🇫🇮",
        unicode"🇨🇮",
        unicode"🇧🇦",
        unicode"🇨🇦"
    ];

    string[] private positions = [
        "GK",
        "RB",
        "CB",
        "LB",
        "RWB",
        "LWB",
        "CDM",
        "CM",
        "CAM",
        "RM",
        "LM",
        "RW",
        "LW",
        "CF",
        "ST"
    ];

    function randomNumberBetween0And(uint256 max, string memory input)
        internal
        pure
        returns (uint256)
    {
        return (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    function getValue(
        uint256 tokenId,
        string memory key,
        string[] memory sourceArray
    ) internal pure returns (uint256) {
        string memory input = string(abi.encodePacked(key, toString(tokenId)));
        bool isStat = sourceArray.length == 0;
        return
            isStat
                ? 55 + randomNumberBetween0And(35, input)
                : randomNumberBetween0And(sourceArray.length, input);
    }

    function getCountry(uint256 tokenId) public view returns (uint256) {
        return getValue(tokenId, "Country", countries);
    }

    function getPosition(uint256 tokenId) public view returns (uint256) {
        return getValue(tokenId, "Position", positions);
    }

    function getFirstStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "First", sourceArray);
    }

    function getSecondStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "Second", sourceArray);
    }

    function getThirdStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "Third", sourceArray);
    }

    function getFourthStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "Fourth", sourceArray);
    }

    function getFifthStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "Fifth", sourceArray);
    }

    function getSixthStat(uint256 tokenId) public pure returns (uint256) {
        string[] memory sourceArray;
        return getValue(tokenId, "Sixth", sourceArray);
    }

    function concat(string memory key, string memory value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(key, ": ", value));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 position = getPosition(tokenId);
        bool isKeeper = position == 0;

        uint256 firstStat = getFirstStat(tokenId);
        uint256 secondStat = getSecondStat(tokenId);
        uint256 thirdStat = getThirdStat(tokenId);
        uint256 fourthStat = getFourthStat(tokenId);
        uint256 fifthStat = getFifthStat(tokenId);
        uint256 sixthStat = getSixthStat(tokenId);
        uint256 overall = (firstStat +
            secondStat +
            thirdStat +
            fourthStat +
            fifthStat +
            sixthStat) / 6;

        string[19] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = concat("Country", countries[getCountry(tokenId)]);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = concat("Position", positions[position]);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = concat("Overall", toString(overall));

        parts[6] = '</text><text x="10" y="100" class="base">';

        parts[7] = concat(isKeeper ? "Diving" : "Pace", toString(firstStat));

        parts[8] = '</text><text x="10" y="120" class="base">';

        parts[9] = concat(
            isKeeper ? "Handling" : "Shooting",
            toString(secondStat)
        );

        parts[10] = '</text><text x="10" y="140" class="base">';

        parts[11] = concat(
            isKeeper ? "Kicking" : "Passing",
            toString(thirdStat)
        );

        parts[12] = '</text><text x="10" y="160" class="base">';

        parts[13] = concat(
            isKeeper ? "Reflexes" : "Dribbling",
            toString(fourthStat)
        );

        parts[14] = '</text><text x="10" y="180" class="base">';

        parts[15] = concat(
            isKeeper ? "Speed" : "Defending",
            toString(fifthStat)
        );

        parts[16] = '</text><text x="10" y="200" class="base">';

        parts[17] = concat(
            isKeeper ? "Positioning" : "Physical",
            toString(sixthStat)
        );

        parts[18] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16],
                parts[17],
                parts[18]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Player #',
                        toString(tokenId),
                        '", "description": "STATS are randomized player attributes generated and stored on chain. Feel free to use STATS in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 10260 && tokenId < 11111, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function claimWithStriker(uint256 tokenId) public nonReentrant {
        bool ownsOG = ogStrikers.ownerOf(tokenId) == msg.sender;
        bool ownsWrapped = wrappedStrikers.ownerOf(tokenId) == msg.sender;
        require(ownsOG || ownsWrapped, "You don't own this Striker!");
        _safeMint(_msgSender(), tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("Stats", "STATS") {}
}
