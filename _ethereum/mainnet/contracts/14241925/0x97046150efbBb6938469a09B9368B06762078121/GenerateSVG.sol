// SPDX-License-Identifier: GPL-3.0

pragma solidity  ^0.8.6;

import "./base64.sol";

library GenerateSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
    }

    struct ContentBounds {
        uint8 y1;
        uint8 x2;
        uint8 y2;
        uint8 x1;
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

    struct TokenURIParams {
        bytes[] parts;
        string background;
    }

    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            SVGParams({ parts: params.parts, background: params.background }),
            palettes
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                image
            )
        );
    }

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
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];

            uint256 currentX = image.bounds.x1;
            uint256 currentY = image.bounds.y1;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    part = string(
                        abi.encodePacked(
                            part,
                            '<rect width="',
                            lookup[rect.length],
                            '" height="10" x="',
                            lookup[32 - currentX - rect.length],
                            '" y="',
                            lookup[currentY],
                            '" fill="#',
                            palette[rect.colorIndex],
                            '" />'
                        )
                    );
                }

                currentX += rect.length;
                if (currentX == image.bounds.x2) {
                    currentX = image.bounds.x1;
                    currentY++;
                }
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            y1: uint8(image[1]),
            x2: uint8(image[2]),
            y2: uint8(image[3]),
            x1: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }

    function generateSVGImage(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(generateSVG(params, palettes)));
    }
}
