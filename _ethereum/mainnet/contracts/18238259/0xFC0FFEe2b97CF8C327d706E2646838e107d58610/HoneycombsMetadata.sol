//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Base64.sol";

import "./HoneycombsArt.sol";
import "./IHoneycombs.sol";
import "./Utilities.sol";

/**
@title  HoneycombsMetadata
@notice Renders ERC721 compatible metadata for Honeycombs.
*/
library HoneycombsMetadata {
    /// @dev Render the JSON Metadata for a given Honeycombs token.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The id of the token to render.
    function tokenURI(IHoneycombs.Honeycombs storage honeycombs, uint256 tokenId) public view returns (string memory) {
        IHoneycombs.Honeycomb memory honeycomb = HoneycombsArt.generateHoneycomb(honeycombs, tokenId);

        // prettier-ignore
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Honeycomb #', Utilities.uint2str(tokenId), '",',
                '"description": "You are searching the world for treasure, but the real treasure is yourself. - Rumi",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(honeycomb.svg),
                    '",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(tokenId, honeycomb.svg)),
                    '",',
                '"attributes": [', attributes(honeycomb), ']',
            '}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    /// @dev Render the JSON atributes for a given Honeycombs token.
    /// @param honeycomb The honeycomb to render.
    function attributes(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                honeycomb.isRevealed ? trait("Canvas Color", honeycomb.canvas.color, ",") : "",
                honeycomb.isRevealed
                    ? trait("Base Hexagon", honeycomb.baseHexagon.hexagonType == 0 ? "Flat Top" : "Pointy Top", ",")
                    : "",
                honeycomb.isRevealed ? trait("Base Hexagon Fill Color", honeycomb.baseHexagon.fillColor, ",") : "",
                honeycomb.isRevealed
                    ? trait("Stroke Width", Utilities.uint2str(honeycomb.baseHexagon.strokeWidth), ",")
                    : "",
                honeycomb.isRevealed ? trait("Shape", shapes(honeycomb.grid.shape), ",") : "",
                honeycomb.isRevealed ? trait("Rows", Utilities.uint2str(honeycomb.grid.rows), ",") : "",
                honeycomb.isRevealed ? trait("Rotation", Utilities.uint2str(honeycomb.grid.rotation), ",") : "",
                honeycomb.isRevealed ? trait("Chrome", chromes(honeycomb.gradients.chrome), ",") : "",
                honeycomb.isRevealed ? trait("Duration", durations(honeycomb.gradients.duration), ",") : "",
                honeycomb.isRevealed
                    ? trait("Direction", honeycomb.gradients.direction == 0 ? "Forward" : "Reverse", ",")
                    : "",
                honeycomb.isRevealed == false ? trait("Revealed", "No", ",") : "",
                trait("Day", Utilities.uint2str(honeycomb.stored.day), "")
            );
    }

    /// @dev Get the names for different shapes. Compare HoneycombsArt.getShape().
    /// @param shapeIndex The index of the shape.
    function shapes(uint8 shapeIndex) public pure returns (string memory) {
        return ["Triangle", "Diamond", "Hexagon", "Random"][shapeIndex];
    }

    /// @dev Get the names for different chromes (max colors). Compare HoneycombsArt.getChrome().
    /// @param chrome The chrome of the gradient, which is the number of max colors.
    function chromes(uint8 chrome) public pure returns (string memory) {
        if (chrome <= 6) {
            return ["Monochrome", "Dichrome", "Trichrome", "Tetrachrome", "Pentachrome", "Hexachrome"][chrome - 1];
        } else {
            return "Many";
        }
    }

    /// @dev Get the names for different durations. Compare HoneycombsArt.getDuration().
    /// @param duration The duration in seconds.
    function durations(uint16 duration) public pure returns (string memory) {
        if (duration == 10) {
            return "Rave";
        } else if (duration == 40) {
            return "Normal";
        } else if (duration == 80) {
            return "Soothing";
        } else {
            return "Meditative";
        }
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType,
        string memory traitValue,
        string memory append
    ) public pure returns (string memory) {
        // prettier-ignore
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    /// @dev Generate the HTML for the animation_url in the metadata.
    /// @param tokenId The id of the token to generate the embed for.
    /// @param svg The rendered SVG code to embed in the HTML.
    function generateHTML(uint256 tokenId, bytes memory svg) public pure returns (bytes memory) {
        // prettier-ignore
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Honeycomb ', Utilities.uint2str(tokenId), '</title>',
                '<style>',
                    'html,',
                    'body {',
                        'margin: 0;',
                        'background: #EFEFEF;',
                        'overflow: hidden;',
                    '}',
                    'svg {',
                        'max-width: 100vw;',
                        'max-height: 100vh;',
                    '}',
                '</style>',
            '</head>',
            '<body>',
                svg,
            '</body>',
            '</html>'
        );
    }
}
