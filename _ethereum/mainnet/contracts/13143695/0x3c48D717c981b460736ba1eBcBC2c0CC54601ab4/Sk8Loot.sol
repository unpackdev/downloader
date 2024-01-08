// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Sk8Loot is ERC721Enumerable, ReentrancyGuard, Ownable {
    string[] private bearings = ["Very Very Fast", "Very Fast", "Fast", "Slow"];

    string[] private bushings = ["Hella Hard", "Hard", "Soft", "Super Soft"];

    string[] private decks = [
        "Punk",
        "Old School",
        "Longboard",
        "Cruiser",
        "Popsicle"
    ];

    string[] private colors = [
        "Pitch Black",
        "Mirror Chrome",
        "Rainbow",
        "Hot Pink",
        "Slime Green",
        "Tie-dye",
        "Dusty Brown",
        "Neon Blue",
        "Radical Red",
        "Banana Yellow"
    ];

    string[] private patterns = [
        "Zebra Print",
        "Caution Tape",
        "Marble Pattern",
        "Camo",
        "Checkered",
        "Stripes",
        "Zig Zag"
    ];

    string[] private icons = [
        "a Skull",
        "a Mushroom",
        "a Twisted Dragon",
        "a Plant Leaf",
        "a Snake",
        "a Fishbone",
        "Clouds",
        "a UFO",
        "the Eye of Ra",
        "a Middle Finger",
        "Flames",
        "a Pizza Slice"
    ];

    string[] private griptape = [
        "Marble",
        "Caution",
        "Zig Zag",
        "Stripe",
        "Worn",
        "Black"
    ];

    string[] private hardware = ["Gold", "Solid", "Decent", "Cheap"];

    string[] private trucks = ["Platinum", "Gold", "Steel", "Metal", "Plastic"];

    string[] private wheels = ["Diamond", "Marble", "Polyurethane", "Clay"];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBearings(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BEARINGS", bearings);
    }

    function getBushings(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "BUSHINGS", bushings);
    }

    function getDeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DECK", decks);
    }

    function getDesign(uint256 tokenId) public view returns (string memory) {
        string memory color = pluck(tokenId, "COLORS", colors);
        string memory pattern = pluck(tokenId, "PATTERNS", patterns);
        string memory icon = pluck(tokenId, "ICONS", icons);

        return string(abi.encodePacked(color, " ", pattern, " with ", icon));
    }

    function getGriptape(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GRIPTAPE", griptape);
    }

    function getHardware(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HARDWARE", hardware);
    }

    function getTrucks(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TRUCKS", trucks);
    }

    function getWheels(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WHEELS", wheels);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        return sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getBearings(tokenId);

        parts[2] = ' Bearings</text><text x="10" y="40" class="base">';

        parts[3] = getBushings(tokenId);

        parts[4] = ' Bushings</text><text x="10" y="60" class="base">';

        parts[5] = getDeck(tokenId);

        parts[6] = ' Deck</text><text x="10" y="80" class="base">';

        parts[7] = getGriptape(tokenId);

        parts[8] = ' Griptape</text><text x="10" y="100" class="base">';

        parts[9] = getHardware(tokenId);

        parts[10] = ' Hardware</text><text x="10" y="120" class="base">';

        parts[11] = getTrucks(tokenId);

        parts[12] = ' Trucks</text><text x="10" y="140" class="base">';

        parts[13] = getWheels(tokenId);

        parts[14] = ' Wheels</text><text x="10" y="160" class="base">';

        parts[15] = getDesign(tokenId);

        parts[16] = "</text></svg>";

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
                        '{"name": "Board #',
                        toString(tokenId),
                        '", "description": "skate or die.", "image": "data:image/svg+xml;base64,',
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
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
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

    constructor() ERC721("Sk8Loot", "SK8LOOT") Ownable() {}
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
