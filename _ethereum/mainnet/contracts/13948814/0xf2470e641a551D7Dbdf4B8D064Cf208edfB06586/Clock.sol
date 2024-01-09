pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import "./SafeERC20.sol";

contract Clock8008 is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // Set UTC timezone
    mapping(uint256 => int8) timeLocalization;

    string[] private brands = [
        "Timex",
        "HMT",
        "Fossil",
        "Swatch",
        "Stuhrling",
        "Seagull",
        "Seiko",
        "Invicta",
        "Swiss Legend",
        "Guess",
        "Nixon",
        "Rotary",
        "Citizen",
        "Orient",
        "Casio",
        "Skagen",
        "Vostok",
        "Bulova",
        "Diesel",
        "Mondaine",
        "Benrus",
        "Michael Kors",
        "Marathon",
        "Certina",
        "Suunto",
        "Luminox",
        "Tissot",
        "Frederique Constant",
        "Stowa",
        "Laco",
        "Hamilton",
        "Christopher Ward",
        "Maurice Lacroix",
        "Zodiac",
        "Gucci",
        "Movado",
        "Mido",
        "Rado",
        "Longines",
        "Raymond Weil",
        "Oris",
        "Tutima",
        "Sinn",
        "Fortis",
        "Junghans",
        "Baume et Mercier",
        "Hermes",
        "Nomos Glashutte",
        "Tag Heuer",
        "Ebel",
        "Doxa",
        "Tudor",
        "Bell & Ross",
        "Ball",
        "Montblac",
        "IWC",
        "Omega",
        "Grand Seiko",
        "Bvlgari",
        "Breitling",
        "Chronoswiss",
        "Bremont",
        "Zenith",
        "Hublot",
        "Carier",
        "Panerai",
        "Rolex",
        "Jaeger-LeCoultre",
        "Chopard",
        "Ulysse Nardin",
        "Girard-Perregaux",
        "Blancpain",
        "Glashutte Original",
        "Breguet",
        "A. Lange & Sohne",
        "Piaget",
        "Audemars Piguet",
        "Franck Muller",
        "Patek Philippe",
        "Vacheron Constantin",
        "Richard Mille",
        "MB&F",
        "F.P. Journe",
        "Philippe Dufour",
        "80085",
        "Paradigm",
        "Polychain",
        "Sino",
        "FTX",
        "Degen",
        "DeFi Summer",
        "Apes",
        "Rugged",
        "Layer 2",
        "MEV",
        "Flashbots",
        "Zero Knowledge",
        "x y = k"
    ];

    uint256[] private themes = [
        0, // "default",
        1, // "dark",
        2, // "vintage",
        3, // "emarald",
        4 // "sapphire"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBrand(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BRAND", brands);
    }

    // Returns colors
    // primary, accent, background, hand, text
    function getColors(uint256 tokenId) public view returns (string[5] memory) {
        uint256 rand = random(
            string(abi.encodePacked("COLORS", Utils.toString(tokenId)))
        );
        uint256 themeId = themes[rand % themes.length];

        // Dark
        if (themeId == 1) {
            return ["#232323", "#35adf2", "#353535", "#000", "#c8c8c8"];
        }

        // Vintage
        if (themeId == 2) {
            return ["#c0a675", "#c5a35b", "#cfc5ab", "#be975e", "#514a39"];
        }

        // Emarald
        if (themeId == 3) {
            return ["#f6f6f6", "#c3c6c3", "#0c5f35", "#eaeff0", "#fff"];
        }

        // Sapphire
        if (themeId == 4) {
            return ["#b6b4b2", "#a8a8a8", "#0a367e", "#ababad", "#b5c9cf"];
        }

        // Default
        return ["#9f9f9f", "#ff3636", "#fff", "#000", "#000"];
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Utils.toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        int8 offset = timeLocalization[tokenId];

        string[5] memory colors = getColors(tokenId);

        string[17] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" class="clock" viewBox="0 0 100 100" style="width:420px;height:420px;"> <style> * {';

        parts[1] = string(
            abi.encodePacked("--color-primary: ", colors[0], ";")
        );

        parts[2] = string(abi.encodePacked("--color-accent: ", colors[1], ";"));
        parts[3] = string(
            abi.encodePacked("--color-background: ", colors[2], ";")
        );
        parts[4] = string(abi.encodePacked("--color-hand: ", colors[3], ";"));
        parts[5] = string(abi.encodePacked("--color-text: ", colors[4], ";"));

        parts[
            6
        ] = "-webkit-transform-origin: inherit; transform-origin: inherit; display: flex; align-items: center; justify-content: center; margin: 0; background-color: var(--color-background); font-family: Helvetica, Sans-Serif; font-size: 5px; } .text { color: var(--color-text); } .circle { color: var(--color-accent); } .clock { width: 60vmin; height: 60vmin; fill: currentColor; -webkit-transform-origin: 50px 50px; transform-origin: 50px 50px; -webkit-animation-name: fade-in; animation-name: fade-in; -webkit-animation-duration: 500ms; animation-duration: 500ms; -webkit-animation-fill-mode: both; animation-fill-mode: both; } .clock line { stroke: currentColor; stroke-linecap: round; } .lines { color: var(--color-primary); stroke-width: 0.5px; } .line-1 { -webkit-transform: rotate(30deg); transform: rotate(30deg); } .line-2 { -webkit-transform: rotate(60deg); transform: rotate(60deg); } .line-3 { -webkit-transform: rotate(90deg); transform: rotate(90deg); } .line-4 { -webkit-transform: rotate(120deg); transform: rotate(120deg); } .line-5 { -webkit-transform: rotate(150deg); transform: rotate(150deg); } .line-6 { -webkit-transform: rotate(180deg); transform: rotate(180deg); } .line-7 { -webkit-transform: rotate(210deg); transform: rotate(210deg); } .line-8 { -webkit-transform: rotate(240deg); transform: rotate(240deg); } .line-9 { -webkit-transform: rotate(270deg); transform: rotate(270deg); } .line-10 { -webkit-transform: rotate(300deg); transform: rotate(300deg); } .line-11 { -webkit-transform: rotate(330deg); transform: rotate(330deg); } .line-12 { -webkit-transform: rotate(360deg); transform: rotate(360deg); } .line { stroke-width: 1.5px; transition: -webkit-transform 200ms cubic-bezier(0.175, 0.885, 0.32, 1.275); transition: transform 200ms cubic-bezier(0.175, 0.885, 0.32, 1.275); transition: transform 200ms cubic-bezier(0.175, 0.885, 0.32, 1.275), -webkit-transform 200ms cubic-bezier(0.175, 0.885, 0.32, 1.275); } .line-hour { color: var(--color-hand); animation: rotateClockHour 216000s linear infinite; } .line-minute { color: var(--color-hand); animation: rotateClockMinute 3600s linear infinite; } .line-second { color: var(--color-accent); stroke-width: 1px; animation: rotateClockSecond 60s linear infinite; }";
        parts[7] = Utils.getKeyFrames(offset);
        parts[8] = "</style>";

        parts[
            9
        ] = '<text class="text" x="50%" y="30%" dominant-baseline="middle" text-anchor="middle">';
        parts[10] = getBrand(tokenId);
        parts[11] = "</text>";

        parts[
            12
        ] = '<text class="text" style="font-size: 2px" x="50%" y="70%" dominant-baseline="middle" text-anchor="middle">UTC';
        parts[13] = offset >= 0 ? "+" : "-";

        if (offset < 0) {
            offset = offset * -1;
        }

        parts[14] = Utils.toString(uint256(int256(offset)));
        parts[15] = "</text>";
        parts[
            16
        ] = '<g class="lines"> <line class="line line-1" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-2" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-3" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-4" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-5" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-6" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-7" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-8" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-9" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-10" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-11" x1="50" y1="5" x2="50" y2="10"></line> <line class="line line-12" x1="50" y1="5" x2="50" y2="10"></line> </g> <line class="line line-hour" x1="50" y1="25" x2="50" y2="50"></line> <line class="line line-minute" x1="50" y1="10" x2="50" y2="50"></line> <circle class="circle" cx="50" cy="50" r="3"></circle> <g class="line line-second"> <line x1="50" y1="10" x2="50" y2="60"></line> <circle cx="50" cy="50" r="1.5"></circle> </g> </svg>';

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
                parts[16]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Clock #',
                        Utils.toString(tokenId),
                        '", "description": "Clock8008 is a collection of 8008 functioning clocks that you can own in the metaverse. Crafted with scrupulous attention to detail, Clock8008 redefines timekeeping in the metaverse while being a timeless staple.", "image": "data:image/svg+xml;base64,',
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

    function setLocalization(uint256 tokenId, int8 localization) public {
        require(msg.sender == ownerOf(tokenId), "Shoo");
        require(localization >= -12 && localization <= 14, "boo!");
        timeLocalization[tokenId] = localization;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        // 0.1 ETH to mint
        require(msg.value >= 1e17, "Timekeeping aint free!");
        require(tokenId > 0 && tokenId < 8001, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 8000 && tokenId < 8009, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    function withdrawETH(address recipient) public onlyOwner {
        recipient.call{value: address(this).balance}("");
    }

    function withdrawERC20(address token, address recipient) public onlyOwner {
        IERC20(token).safeTransfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    constructor() ERC721("Clock", "CLOCK") Ownable() {}
}

library Utils {
    // Gets all the CSS key frames
    function getKeyFrames(int8 offset) internal view returns (string memory) {
        uint256 secs = BokkyPooBahsDateTimeLibrary.getSecond(block.timestamp);
        uint256 mins = BokkyPooBahsDateTimeLibrary.getMinute(block.timestamp);
        uint256 hrs = BokkyPooBahsDateTimeLibrary.getHour(block.timestamp);

        // Shift time
        if (offset < 0) {
            // Don't underflow
            if (hrs < uint256(int256(offset) * -1)) {
                hrs = hrs + 12;
            }

            // Subtract
            hrs = hrs - uint256(int256(offset) * -1);
        } else {
            hrs = hrs + uint256(int256(offset));
        }

        // Bound between 0 - 12
        hrs = hrs % 12;

        // Get degress
        uint256 secDeg = ((secs * 360) / 60);
        uint256 minDeg = ((mins * 360) / 60);
        uint256 hourDeg = (((hrs * 350) / 12)) + (((mins * 30) / 60));

        // Paths
        string[3] memory parts;
        parts[0] = toKeyFrames("rotateClockSecond", secDeg);
        parts[1] = toKeyFrames("rotateClockMinute", minDeg);
        parts[2] = toKeyFrames("rotateClockHour", hourDeg);

        // Convert to key frames
        return string(abi.encodePacked(parts[0], parts[1], parts[2]));
    }

    // Get the CSS for key frames
    function toKeyFrames(string memory name, uint256 degree)
        internal
        pure
        returns (string memory)
    {
        string memory strDegree = toString(degree);
        string memory strDegreeEnd = toString(degree + 360);

        string[33] memory paths;

        paths[0] = "@keyframes ";
        paths[1] = name;
        paths[2] = " {";
        paths[3] = "from { -webkit-transform: rotate(";
        paths[4] = strDegree;
        paths[5] = "deg);";
        paths[6] = "-moz-transform: rotate(";
        paths[7] = strDegree;
        paths[8] = "deg);";
        paths[9] = "-ms-transform: rotate(";
        paths[10] = strDegree;
        paths[11] = "deg);";
        paths[12] = "-o-transform: rotate(";
        paths[13] = strDegree;
        paths[14] = "deg);";
        paths[15] = "transform: rotate(";
        paths[16] = strDegree;
        paths[17] = "deg); }";
        paths[18] = "to { -webkit-transform: rotate(";
        paths[19] = strDegreeEnd;
        paths[20] = "deg);";
        paths[21] = "-moz-transform: rotate(";
        paths[22] = strDegreeEnd;
        paths[23] = "deg);";
        paths[24] = "-ms-transform: rotate(";
        paths[25] = strDegreeEnd;
        paths[26] = "deg);";
        paths[27] = "-o-transform: rotate(";
        paths[28] = strDegreeEnd;
        paths[29] = "deg);";
        paths[30] = "transform: rotate(";
        paths[31] = strDegreeEnd;
        paths[32] = "deg); } }";

        string memory output = string(
            abi.encodePacked(
                paths[0],
                paths[1],
                paths[2],
                paths[3],
                paths[4],
                paths[5],
                paths[6],
                paths[7],
                paths[8]
            )
        );

        output = string(
            abi.encodePacked(
                output,
                paths[9],
                paths[10],
                paths[11],
                paths[12],
                paths[13],
                paths[14],
                paths[15],
                paths[16]
            )
        );

        output = string(
            abi.encodePacked(
                output,
                paths[17],
                paths[18],
                paths[19],
                paths[20],
                paths[21],
                paths[22],
                paths[23],
                paths[24]
            )
        );

        output = string(
            abi.encodePacked(
                output,
                paths[25],
                paths[26],
                paths[27],
                paths[28],
                paths[29],
                paths[30],
                paths[31],
                paths[32]
            )
        );

        return output;
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
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;

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
}
