// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

library RLEtoSVG {
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
        ContentBounds bounds;
        Rect[] rects;
    }

    struct PigeonMetadata {
        uint8 headColorIndex;
        uint8 eyeColorIndex;
        uint8 beakColorIndex;
        uint8 bodyColorIndex;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(
        bytes memory pigeonRLE,
        string[] memory headPalette,
        string[] memory bodyPalette,
        string memory background
    ) internal pure returns (string memory svg) {
        // prettier-ignore
        return string(
            abi.encodePacked(
                // solhint-disable-next-line max-line-length
                '<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', background, '" />',
                '<g transform="translate(40, 25)">',
                _generateSVGRects(pigeonRLE, headPalette, bodyPalette),
                '</g>',
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    function _generateSVGRects(
        bytes memory pigeonRLE,
        string[] memory headPalette,
        string[] memory bodyPalette
    ) private pure returns (string memory svg) {
        // prettier-ignore
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70',
            '80', '90', '100', '110', '120', '130', '140', '150',
            '160', '170', '180', '190', '200', '210', '220', '230',
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320'
        ];

        DecodedImage memory image = _decodeRLEImage(pigeonRLE);
        uint256 currentX = image.bounds.left;
        uint256 currentY = image.bounds.top;

        uint256 cursor;
        string[16] memory buffer;
        string memory part;
        string memory rects;

        for (uint256 i = 0; i < image.rects.length; i++) {
            Rect memory rect = image.rects[i];
            if (rect.colorIndex != 0) {
                buffer[cursor] = lookup[rect.length]; // width
                buffer[cursor + 1] = lookup[currentX]; // x
                buffer[cursor + 2] = lookup[currentY]; // y

                uint8 colorIndex = rect.colorIndex;
                buffer[cursor + 3] = bodyPalette[colorIndex]; // color

                if (colorIndex <= 6) {
                    buffer[cursor + 3] = headPalette[colorIndex]; // color
                }
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
                    // solhint-disable-next-line max-line-length
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({length: uint8(image[i]), colorIndex: uint8(image[i + 1])});
            cursor++;
        }
        return DecodedImage({bounds: bounds, rects: rects});
    }

    function _getPigeonMetadata(bytes memory pigeon) internal pure returns (PigeonMetadata memory) {
        DecodedImage memory image = _decodeRLEImage(pigeon);

        // Literally counted pixels/rectangles in a PNG file to derive these.
        return
            PigeonMetadata({
                headColorIndex: image.rects[4].colorIndex,
                eyeColorIndex: image.rects[9].colorIndex,
                beakColorIndex: image.rects[24].colorIndex,
                bodyColorIndex: image.rects[35].colorIndex
            });
    }
}
