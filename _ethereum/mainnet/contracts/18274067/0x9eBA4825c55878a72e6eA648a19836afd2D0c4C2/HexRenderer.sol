// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Base64.sol";
import "./Strings.sol";
import "./IERC721.sol";
import "./IRenderer.sol";
import "./IHex.sol";

contract HexRenderer is IRenderer {
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    IHex private immutable _hexContract;
    mapping(uint256 => bool) private _drawMap0;
    mapping(uint256 => bool) private _drawMap1;
    mapping(uint256 => bool) private _drawMap2;
    mapping(uint256 => bool) private _drawMap3;
    mapping(uint256 => mapping(uint256 => string)) private _fillColors;

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(IHex hexContract) {
        _hexContract = hexContract;

        uint8[8] memory set0 = [1, 5, 6, 7, 0xb, 0xc, 0xd, 0xf];
        uint8[8] memory set1 = [2, 5, 8, 9, 0xb, 0xc, 0xe, 0xf];
        uint8[8] memory set2 = [3, 6, 0x8, 0xa, 0xb, 0xd, 0xe, 0xf];
        uint8[8] memory set3 = [4, 7, 9, 0xa, 0xc, 0xd, 0xe, 0xf];
        for (uint256 i = 0; i < set0.length; i++) {
            _drawMap0[set0[i]] = true;
        }
        for (uint256 i = 0; i < set1.length; i++) {
            _drawMap1[set1[i]] = true;
        }
        for (uint256 i = 0; i < set2.length; i++) {
            _drawMap2[set2[i]] = true;
        }
        for (uint256 i = 0; i < set3.length; i++) {
            _drawMap3[set3[i]] = true;
        }
        _fillColors[1][0] = "B0AAA7";
        _fillColors[1][1] = "E83D05";
        _fillColors[1][2] = "ED0004";
        _fillColors[1][3] = "FAB905";
        _fillColors[1][4] = "DCC7BB";
        _fillColors[1][5] = "3D3236";
        _fillColors[1][6] = "3B657D";
        _fillColors[1][7] = "748C58";
        _fillColors[2][0] = "333333";
        _fillColors[2][1] = "EEEEEE";
        _fillColors[2][2] = "FFB6C1";
        _fillColors[2][3] = "008080";
        _fillColors[2][4] = "FF4500";
        _fillColors[2][5] = "FFD700";
        _fillColors[2][6] = "9400D3";
        _fillColors[2][7] = "00BFFF";
        _fillColors[3][0] = "222222";
        _fillColors[3][1] = "333333";
        _fillColors[3][2] = "555555";
        _fillColors[3][3] = "FF0000";
        _fillColors[3][4] = "00CDDA";
        _fillColors[4][0] = "F29C1B";
        _fillColors[4][1] = "5692B0";
        _fillColors[4][2] = "F05630";
        _fillColors[4][3] = "2B2728";
        _fillColors[4][4] = "D1CABC";
        _fillColors[5][0] = "202A2D";
        _fillColors[5][1] = "2A5371";
        _fillColors[5][2] = "3E5977";
        _fillColors[5][3] = "891528";
        _fillColors[5][4] = "663446";
        _fillColors[5][5] = "8A839E";
        _fillColors[5][6] = "DED2E0";
        _fillColors[5][7] = "F3EAF4";
        _fillColors[5][8] = "E59CA1";
    }

    /* -------------------------------------------------------------------------- */
    /*                                     SVG                                    */
    /* -------------------------------------------------------------------------- */
    function renderSVG(uint256 tokenId) external view returns (string memory) {
        string memory svgString = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2640 3920"><rect x="0" y="0" width="2640" height="3920" fill="#',
            tokenId == 1
                ? "D4D1BB"
                : tokenId == 2 ? "DDDDDD" : tokenId == 3 ? "000000" : tokenId == 4 ? "A6BCC3" : "ECDEDF",
            '"/>'
        );

        uint256 hashCount = _hexContract.getTokenDataLength(tokenId);
        for (
            uint256 globalCharIndex = hashCount > 16 ? (hashCount - 16) * 64 : 0;
            globalCharIndex < hashCount * 64;
            globalCharIndex++
        ) {
            uint256 hashIndex = globalCharIndex / 64;
            uint256 charIndex = globalCharIndex % 64;
            uint256 chunkIndex = charIndex / 4;
            bytes32 hash = _hexContract.getTokenDataHash(tokenId, hashIndex);
            uint256 chunkValue = _getChunkValue(hash, chunkIndex);
            svgString =
                string.concat(svgString, _getPathString(tokenId, hashIndex, hash, hashCount, charIndex, chunkValue));
        }
        return string.concat(svgString, "</svg>");
    }

    function _getPathString(
        uint256 tokenId,
        uint256 hashIndex,
        bytes32 hash,
        uint256 hashCount,
        uint256 charIndex,
        uint256 chunkValue
    ) internal view returns (string memory) {
        uint256 charValue = _getUintAtPosition(hash, charIndex);
        string memory pathString;
        {
            uint256 x = (charIndex % 32) * 40 * 2 + 30;
            uint256 ySize = 1920 / (hashCount > 16 ? 16 : hashCount);
            uint256 y = 40
                + (
                    (charIndex / 4) < 8
                        ? (hashCount > 16 ? hashIndex - (hashCount - 16) : hashIndex) * 2
                        : (hashCount > 16 ? hashIndex - (hashCount - 16) : hashIndex) * 2 + 1
                ) * ySize;
            bool even = chunkValue / 4 < charValue;
            pathString = _getPath(x, y, charValue, even, ySize);
        }
        return string.concat(
            '<path d="',
            pathString,
            '" fill="#',
            _getFillColor(tokenId, charValue, hash, charIndex, hashIndex),
            '" stroke="#',
            tokenId == 1
                ? "333333"
                : tokenId == 2 ? "111111" : tokenId == 3 ? "444444" : tokenId == 4 ? "111111" : "11111177",
            '" stroke-width="0.',
            Strings.toString((uint256(hash) % 90) + 10),
            '"/>'
        );
    }

    function _getPath(uint256 x, uint256 y, uint256 charValue, bool even, uint256 ySize)
        internal
        view
        returns (string memory)
    {
        return string.concat(
            _drawBlock(x, y, _drawMap0[charValue], even, ySize),
            _drawBlock(x + 20, y, _drawMap1[charValue], even, ySize),
            _drawBlock(x + 40, y, _drawMap2[charValue], even, ySize),
            _drawBlock(x + 60, y, _drawMap3[charValue], even, ySize)
        );
    }

    function _drawBlock(uint256 x, uint256 y, bool fill, bool pivot, uint256 ySize)
        internal
        pure
        returns (string memory)
    {
        uint256 ysideA = pivot ? 0 : ySize;
        uint256 ysideB = pivot ? ySize : 0;
        string memory yA = Strings.toString(y + ysideA);
        string memory yB = Strings.toString(y + ysideB);
        string memory x0 = Strings.toString(x);
        string memory x1 = Strings.toString(x + 20);
        string memory x2 = Strings.toString(x + 40);
        if (fill) {
            string memory fillPath = string.concat("M", x0, " ", yA, "L", x1, " ", yB, "L", x2, " ", yB, "L", x1, " ");
            fillPath = string.concat(fillPath, yA, "L", x0, " ", yA, "H", x1, "L", x2, " ", yB, "H", x1);
            fillPath = string.concat(fillPath, "L", x0, " ", yA, " Z");
            return string.concat(fillPath, _constructAddition(x, y, ysideA, ysideB));
        } else {
            string memory base = string.concat("M", x0, " ", yA, "L", x1, " ", yB, "H", x2, "L", x1, " ", yA, "Z");
            return string.concat(base, _constructAddition(x, y, ysideA, ysideB));
        }
    }

    function _constructAddition(uint256 x, uint256 y, uint256 ysideA, uint256 ysideB)
        internal
        pure
        returns (string memory)
    {
        string memory yA = Strings.toString(((y + ysideA) * 100 + _random(x, y, 0) - 500) / 100);
        string memory yB = Strings.toString(((y + ysideB) * 100 + _random(x, y, 1) - 500) / 100);
        string memory x0 = Strings.toString((x * 100 + _random(x, y, 2) - 500) / 100);
        string memory x1 = Strings.toString(((x + 20) * 100 + _random(x, y, 3) - 500) / 100);
        string memory x2 = Strings.toString(((x + 40) * 100 + _random(x, y, 4) - 500) / 100);
        return string.concat("M", x0, " ", yA, "L", x1, " ", yB, "Z M", x2, " ", yB, "L", x1, " ", yA, "Z");
    }

    function _random(uint256 x, uint256 y, uint256 offset) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(x, y, offset))) % 1000;
    }

    function _getChunkValue(bytes32 hash, uint256 index) internal pure returns (uint256) {
        return _getUintAtPosition(hash, index * 4) + _getUintAtPosition(hash, index * 4 + 1)
            + _getUintAtPosition(hash, index * 4 + 2) + _getUintAtPosition(hash, index * 4 + 3);
    }

    function _getUintAtPosition(bytes32 hash, uint256 position) internal pure returns (uint256) {
        return (position % 2 == 0) ? uint256(uint8(hash[position / 2])) / 16 : uint256(uint8(hash[position / 2])) % 16;
    }

    function _getFillColor(uint256 tokenId, uint256 value, bytes32 hash, uint256 charIndex, uint256 hashIndex)
        internal
        view
        returns (string memory)
    {
        return charIndex > 0 && charIndex < 63
            && value > _getUintAtPosition(hash, charIndex - 1) + _getUintAtPosition(hash, charIndex + 1)
            && (
                IERC721(address(_hexContract)).ownerOf(tokenId) == _hexContract.getTokenDataFrom(tokenId, hashIndex)
                    || hashIndex < 2
            )
            ? _fillColors[tokenId][value % ((tokenId == 1 || tokenId == 2) ? 8 : (tokenId == 3 || tokenId == 4) ? 5 : 9)]
            : "111111";
    }
}
