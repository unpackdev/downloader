// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

library MultiPartRLEToSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
    }

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    struct DecodedGlasses {
        uint8 paletteIndex;
        uint8 isHalfMoon;
        uint8[5][] shapes;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
      {
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', 
            '80', '90', '100', '110', '120', '130', '140', '150', 
            '160', '170', '180', '190', '200', '210', '220', '230', 
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320' 
        ];
        string memory rects;
        string[5] memory shape;
        string memory part;
        string[] storage palette;
        for (uint8 p = 0; p < params.parts.length; p++) {
            if (p == 3) {
                DecodedGlasses memory glasses = _decodeRLEGlasses(params.parts[p]);
                palette = palettes[glasses.paletteIndex];
                for (uint256 i = 0; i < glasses.shapes.length; i++) {
                    shape[0] = palette[glasses.shapes[i][0]];   // colorIdx
                    shape[1] = lookup[glasses.shapes[i][1]];    // svg shape param 1
                    shape[2] = lookup[glasses.shapes[i][2]];    // svg shape param 2
                    shape[3] = lookup[glasses.shapes[i][3]];    // svg shape param 3
                    shape[4] = lookup[glasses.shapes[i][4]];    // svg shape param 4
                    if (i < 2) {
                        part = string(abi.encodePacked(part, _drawRect(shape)));
                    } else if (i < 4) {
                        part = string(abi.encodePacked(part, _drawCircle(shape)));
                    } else {
                    if (glasses.isHalfMoon == 1) {
                        part = string(abi.encodePacked(part, _drawPath(shape)));
                    } else {
                        part = string(abi.encodePacked(part, _drawRect(shape)));
                    }
                    }
                }
                rects = string(abi.encodePacked(rects, part));
                return rects;
            }
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;
            
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];

                if (p != 3 && rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Return an svg string that draws a circle given the provided `shape`.
     */
    // prettier-ignore
    function _drawCircle(string[5] memory shape) private pure returns (string memory) {
    return string(abi.encodePacked('<circle r="', shape[1],'" cx="',shape[2],'" cy="',shape[3],'" fill="#',shape[0],'" shape-rendering="geometricPrecision"/>'));
    }

    /**
     * @notice Return an svg string that draws a rectangle given the provided `shape`.
     */
    // prettier-ignore
    function _drawRect(string[5] memory shape) private pure returns (string memory) {
    return string(abi.encodePacked('<rect width="', shape[1], '" height="', shape[2],'" x="', shape[3], '" y="', shape[4], '" fill="#', shape[0], '" />'));
    }

    /**
     * @notice Return an svg string that draws a path given the provided `shape`.
     */
    // prettier-ignore
    function _drawPath(string[5] memory shape)  private pure returns (string memory) {
        return string(abi.encodePacked('<path d="M', shape[1], ',',shape[2], ' A20,20 0 0 1 ', shape[3],',',shape[4],'" fill="#',shape[0],'" shape-rendering="geometricPrecision"/>'));
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }

    /**
     * @notice Decode a single RLE compressed glasses image into a `DecodedGlasses`.
     */
    function _decodeRLEGlasses(bytes memory image) private pure returns (DecodedGlasses memory) {
        uint256 cursor;
        uint8[5][] memory shapes = new uint8[5][]((image.length - 2) / 5);
        for (uint256 i = 2; i < image.length; i += 5) {
            shapes[cursor] = [
                uint8(image[i]),
                uint8(image[i + 1]),
                uint8(image[i + 2]),
                uint8(image[i + 3]),
                uint8(image[i + 4])
            ];
            cursor++;
        }
        return DecodedGlasses({ paletteIndex: uint8(image[0]), isHalfMoon: uint8(image[1]), shapes: shapes });
    }
}
