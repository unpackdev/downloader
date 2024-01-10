// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./SSTORE2.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./BytesLib.sol";

import "./IBlitoadzRenderer.sol";
import "./IBlitmap.sol";

import "./Integers.sol";

/*  @title Blitoadz Renderer
    @author Clement Walter
    @dev Encode each one of the 56 toadz in a single byte with a leading 57 uint16 for indexes.
         Color palettes is dropped because blitmap colors are used instead.
*/
contract BlitoadzRenderer is Ownable, ReentrancyGuard, IBlitoadzRenderer {
    using Strings for uint256;
    using Integers for uint8;

    // We have a total of 4 * 6 = 24 bits = 3 bytes for coordinates + 1 byte for the color
    // Hence each rect is 4 bytes
    uint8 public constant BITS_PER_FILL_INDEX = 2;

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WH_FILL_TAG =
        "%27%20width=%271%27%20height=%271%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";
    string public constant SVG_TAG_START =
        "%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2036%2036%27%20width=%27360px%27%20height=%27360px%27%3e";
    string public constant SVG_TAG_END =
        "%3cstyle%3erect{shape-rendering:crispEdges}%3c/style%3e%3c/svg%3e";

    address public toadz; // 57 uint16 leading indexes followed by the actual 56 toadz images
    address public toadzNames; // 57 uint16 leading indexes followed by the actual 56 toadz names
    IBlitmap blitmap;

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Indexes and images are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    constructor(address _blitmap) {
        blitmap = IBlitmap(_blitmap);
    }

    function setToadz(bytes calldata _toadz) external onlyOwner {
        toadz = SSTORE2.write(_toadz);
    }

    function setToadzNames(bytes calldata _toadzNames) external onlyOwner {
        toadzNames = SSTORE2.write(_toadzNames);
    }

    function getToadzBytes(uint256 _index) public view returns (bytes memory) {
        uint16 start = BytesLib.toUint16(
            SSTORE2.read(toadz, 2 * _index, 2 * _index + 2),
            0
        );
        uint16 end = BytesLib.toUint16(
            SSTORE2.read(toadz, 2 * _index + 2, 2 * _index + 4),
            0
        );
        return SSTORE2.read(toadz, start + 57 * 2, end + 57 * 2);
    }

    function getToadzName(uint256 _index) public view returns (string memory) {
        uint16 start = BytesLib.toUint16(
            SSTORE2.read(toadzNames, 2 * _index, 2 * _index + 2),
            0
        );
        uint16 end = BytesLib.toUint16(
            SSTORE2.read(toadzNames, 2 * _index + 2, 2 * _index + 4),
            0
        );
        return string(SSTORE2.read(toadzNames, start + 57 * 2, end + 57 * 2));
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(bytes memory palette, uint256 _index)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                uint8(palette[3 * _index]).toString(16, 2),
                uint8(palette[3 * _index + 1]).toString(16, 2),
                uint8(palette[3 * _index + 2]).toString(16, 2)
            );
    }

    function decode1Pixel(
        uint256 index,
        bytes1 _byte,
        string[4] memory palette
    ) internal pure returns (string memory) {
        return
            string.concat(
                RECT_TAG_START,
                (index % 36).toString(),
                Y_TAG,
                (index / 36).toString(),
                WH_FILL_TAG,
                palette[uint8(_byte)],
                RECT_TAG_END
            );
    }

    /// @dev 1 byte is 4 color indexes, so 4 rect
    function decode4Pixels(
        uint256 startIndex,
        bytes1 _byte,
        string[4] memory palette
    ) internal pure returns (string memory) {
        return
            string.concat(
                decode1Pixel(startIndex, _byte >> 6, palette),
                decode1Pixel(startIndex + 1, (_byte & 0x3f) >> 4, palette),
                decode1Pixel(startIndex + 2, (_byte & 0x0f) >> 2, palette),
                decode1Pixel(startIndex + 3, _byte & 0x03, palette)
            );
    }

    function decode16Pixels(
        uint256 startIndex,
        bytes memory _bytes,
        string[4] memory palette
    ) internal pure returns (string memory) {
        return
            string.concat(
                decode4Pixels(startIndex + 0, _bytes[0], palette),
                decode4Pixels(startIndex + 4, _bytes[1], palette),
                decode4Pixels(startIndex + 8, _bytes[2], palette),
                decode4Pixels(startIndex + 12, _bytes[3], palette)
            );
    }

    function decode128Pixels(
        uint256 startIndex,
        bytes memory _bytes,
        string[4] memory palette
    ) internal pure returns (string memory) {
        return
            string.concat(
                decode16Pixels(
                    startIndex + 0,
                    BytesLib.slice(_bytes, 0, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 16,
                    BytesLib.slice(_bytes, 4, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 32,
                    BytesLib.slice(_bytes, 8, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 48,
                    BytesLib.slice(_bytes, 12, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 64,
                    BytesLib.slice(_bytes, 16, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 80,
                    BytesLib.slice(_bytes, 20, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 96,
                    BytesLib.slice(_bytes, 24, 4),
                    palette
                ),
                decode16Pixels(
                    startIndex + 112,
                    BytesLib.slice(_bytes, 28, 4),
                    palette
                )
            );
    }

    function decode1296Pixels(bytes memory _bytes, string[4] memory palette)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                decode128Pixels(
                    0 * 128,
                    BytesLib.slice(_bytes, 0 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    1 * 128,
                    BytesLib.slice(_bytes, 1 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    2 * 128,
                    BytesLib.slice(_bytes, 2 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    3 * 128,
                    BytesLib.slice(_bytes, 3 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    4 * 128,
                    BytesLib.slice(_bytes, 4 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    5 * 128,
                    BytesLib.slice(_bytes, 5 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    6 * 128,
                    BytesLib.slice(_bytes, 6 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    7 * 128,
                    BytesLib.slice(_bytes, 7 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    8 * 128,
                    BytesLib.slice(_bytes, 8 * 32, 32),
                    palette
                ),
                decode128Pixels(
                    9 * 128,
                    BytesLib.slice(_bytes, 9 * 32, 32),
                    palette
                ),
                decode16Pixels(
                    10 * 128,
                    BytesLib.slice(_bytes, 320, 4),
                    palette
                )
            );
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Blitoadz  ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    /// @dev Decode the rect and returns it as a plain string to be used in the svg rect attribute.
    function getBlitoadz(
        uint256 toadzId,
        uint256 blitmapId,
        uint8 paletteOrder
    ) public view returns (string memory) {
        bytes memory toadzBytes = getToadzBytes(toadzId);
        bytes memory palette = BytesLib.slice(
            blitmap.tokenDataOf(blitmapId),
            0,
            12
        );
        string[4] memory paletteHex = [
            getFill(palette, paletteOrder >> 6),
            getFill(palette, (paletteOrder >> 4) & 0x3),
            getFill(palette, (paletteOrder >> 2) & 0x3),
            getFill(palette, paletteOrder & 0x3)
        ];
        return
            string.concat(
                SVG_TAG_START,
                decode1296Pixels(toadzBytes, paletteHex),
                SVG_TAG_END
            );
    }

    function getImageURI(
        uint256 toadzId,
        uint256 blitmapId,
        uint8 paletteOrder
    ) public view returns (string memory) {
        return
            string.concat(
                "data:image/svg+xml,",
                getBlitoadz(toadzId, blitmapId, paletteOrder)
            );
    }

    function tokenURI(
        uint256 toadzId,
        uint256 blitmapId,
        uint8 paletteOrder
    ) public view returns (string memory) {
        return
            string.concat(
                "data:application/json,",
                '{"image_data": "',
                getImageURI(toadzId, blitmapId, paletteOrder),
                '"',
                ',"description": "Blitoadz are a blitmap and CrypToadz cross-breed, paving the way toward a new blitzverse. Oh - and they\'re fully on-chain."',
                ',"name": "',
                getToadzName(toadzId),
                " ",
                blitmap.tokenNameOf(blitmapId),
                '"}'
            );
    }
}
