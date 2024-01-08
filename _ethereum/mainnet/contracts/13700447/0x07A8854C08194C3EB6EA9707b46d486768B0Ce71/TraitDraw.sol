// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice A library with functions to draw VampireGame SVGs
library TraitDraw {
    /// @notice generates an <image> element using base64 encoded PNGs
    /// @param png the base64 encoded PNG data
    /// @return a string with the <image> element
    function drawImageTag(string memory png)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /// @notice draw an SVG using png image data
    /// @param images a list of images generated with drawImageTag
    /// @return the SVG tag with all png images
    function drawSVG(string[] memory images)
        internal
        pure
        returns (string memory)
    {
        bytes memory imagesBytes;

        for (uint256 i = 0; i < images.length; i++) {
            imagesBytes = abi.encodePacked(imagesBytes, images[i]);
        }

        return
            string(
                abi.encodePacked(
                    '<svg id="vampiregame" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    string(imagesBytes),
                    "</svg>"
                )
            );
    }
}
