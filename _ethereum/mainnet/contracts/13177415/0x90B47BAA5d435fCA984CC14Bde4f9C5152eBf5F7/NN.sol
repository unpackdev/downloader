// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";

contract NN is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint8[] private base = [
        0,
        1,
        1,
        2,
        2,
        2,
        3,
        3,
        3,
        3,
        4,
        4,
        4,
        4,
        4,
        5,
        5,
        5,
        5,
        5,
        6,
        6,
        6,
        6,
        7,
        7,
        7,
        8,
        8,
        9
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirst(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "FIRSTA", base), pluck(tokenId, "FIRSTB", base));
    }

    function getSecond(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "SECONDA", base), pluck(tokenId, "SECONDB", base));
    }

    function getThird(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "THIRDA", base), pluck(tokenId, "THIRDB", base));
    }

    function getFourth(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "FOURTHA", base), pluck(tokenId, "FOURTHB", base));
    }

    function getFifth(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "FIFTHA", base), pluck(tokenId, "FIFTHB", base));
    }

    function getSixth(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "SIXTHA", base), pluck(tokenId, "SIXTHB", base));
    }

    function getSeventh(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "SEVENTHA", base), pluck(tokenId, "SEVENTHB", base));
    }

    function getEight(uint256 tokenId) public view returns (uint256, uint256) {
        return (pluck(tokenId, "EIGTHA", base), pluck(tokenId, "EIGTHB", base));
    }

    function pluck(
        uint256 tokenId, 
        string memory keyPrefix, 
        uint8[] memory sourceArray
    ) internal pure returns (uint256) {
        uint256 randFirst = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "1")));
        uint256 randSecond = random(string(abi.encodePacked(keyPrefix, toString(tokenId), "2")));
        uint256 output = sourceArray[randFirst % sourceArray.length] * 10 + randSecond % 10;
        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8801, "Invalid tokenId");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 8800 && tokenId < 8889, "Invalid tokenId");
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        (uint256 a, uint256 b) = getFirst(tokenId);

        parts[1] = toString(a, b);

        parts[2] = '</text><text x="10" y="40" class="base">';

        (a, b) = getSecond(tokenId);

        parts[3] = toString(a, b);

        parts[4] = '</text><text x="10" y="60" class="base">';

        (a, b) = getThird(tokenId);

        parts[5] = toString(a, b);

        parts[6] = '</text><text x="10" y="80" class="base">';

        (a, b) = getFourth(tokenId);

        parts[7] = toString(a, b);

        parts[8] = '</text><text x="10" y="100" class="base">';

        (a, b) = getFifth(tokenId);

        parts[9] = toString(a, b);

        parts[10] = '</text><text x="10" y="120" class="base">';

        (a, b) = getSixth(tokenId);

        parts[11] = toString(a, b);

        parts[12] = '</text><text x="10" y="140" class="base">';

        (a, b) = getSeventh(tokenId);

        parts[13] = toString(a, b);

        parts[14] = '</text><text x="10" y="160" class="base">';

        (a, b) = getEight(tokenId);

        parts[15] = toString(a, b);

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
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
                        '{"name": "NN #',
                        toString(tokenId),
                        '", "description": "NN = N^2 = pair of numbers", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

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

    function toString(uint256 a, uint256 b) internal pure returns (string memory) {
        return string(abi.encodePacked(toString(a), ", ", toString(b)));
    }

    constructor() ERC721("nn", "NN") { }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
