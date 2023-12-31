//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IHoneycombs.sol";
import "./Utilities.sol";
import "./Colors.sol";

/**
@title  GradientsArt
@notice Generates the gradients for a given Honeycomb.
*/
library GradientsArt {
    enum HEXAGON_TYPE { FLAT, POINTY } // prettier-ignore
    enum SHAPE { TRIANGLE, DIAMOND, HEXAGON, RANDOM } // prettier-ignore

        /// @dev Get from different chromes or max primary colors. Corresponds to chrome trait in HoneycombsMetadata.sol.
    function getChrome(uint8 index) public pure returns (uint8) {
        return uint8([1, 2, 3, 4, 5, 6, Colors.COLORS().length][index]);
    }

    /// @dev Get from different animation durations in seconds. Corresponds to duration trait in HoneycombsMetadata.sol.
    function getDuration(uint16 index) public pure returns (uint16) {
        return uint16([10, 40, 80, 240][index]);
    }

    /// @dev Get the linear gradient's svg.
    /// @param data The gradient data.
    function getLinearGradientSvg(GradientData memory data) public pure returns (bytes memory) {
        // prettier-ignore
        bytes memory svg = abi.encodePacked(
            '<linearGradient id="gradient', Utilities.uint2str(data.gradientId), '" x1="0%" x2="0%" y1="', 
                    Utilities.uint2str(data.y1), '%" y2="', Utilities.uint2str(data.y2), '%">',
                '<stop stop-color="', data.stop1.color, '">',
                    '<animate attributeName="stop-color" values="', data.stop1.animationColorValues, '" dur="', 
                        Utilities.uint2str(data.duration), 's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
                '<stop offset="0.', Utilities.uint2str(data.offset), '" stop-color="', data.stop2.color, '">',
                    '<animate attributeName="stop-color" values="', data.stop2.animationColorValues, '" dur="', 
                        Utilities.uint2str(data.duration), 's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
            '</linearGradient>'
        );

        return svg;
    }

    /// @dev Get the stop for a linear gradient.
    /// @param honeycomb The honeycomb data used for rendering.
    /// @param stopCount The current stop count - used for seeding the random number generator.
    function getLinearGradientStopSvg(
        IHoneycombs.Honeycomb memory honeycomb,
        uint8 stopCount
    ) public pure returns (GradientStop memory) {
        GradientStop memory stop;
        string[46] memory allColors = Colors.COLORS();

        // Get random stop color.
        uint256 currentIndex = Utilities.random(
            honeycomb.seed,
            abi.encodePacked("linearGradientStop", Utilities.uint2str(stopCount)),
            allColors.length
        );
        stop.color = abi.encodePacked("#", allColors[currentIndex]);

        bytes memory values;
        // Add the initial color.
        values = abi.encodePacked(values, stop.color, ";");

        // Get all animation values based on the direction.
        bool forwardDirection = honeycomb.gradients.direction == 0;

        // We pick 14 more different colors for the gradient.
        uint8 count = 14;
        for (uint256 i = 0; i <= (count * 2) - 2; ) {
            bool isFirstHalf = i < count;

            // For the first half, follow the direction. For the second half, reverse the direction.
            if (isFirstHalf == forwardDirection) {
                currentIndex = (currentIndex + 2) % allColors.length;
            } else {
                currentIndex = (currentIndex + allColors.length - 2) % allColors.length;
            }

            values = abi.encodePacked(values, "#", allColors[currentIndex], ";");
            unchecked {
                ++i;
            }
        }

        // Add the last color.
        stop.animationColorValues = abi.encodePacked(values, stop.color);
        return stop;
    }

    /// @dev Get all gradients data, particularly the svg.
    /// @param honeycomb The honeycomb data used for rendering.
    function generateGradientsSvg(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        bytes memory svg;

        // Initialize array of stops (id => svgString) for reuse once we reach the max color count.
        GradientStop[] memory stops = new GradientStop[](honeycomb.grid.totalGradients + 1);

        uint8 stopCount;
        GradientStop memory prevStop = getLinearGradientStopSvg(honeycomb, stopCount);
        stops[stopCount] = prevStop;
        ++stopCount;

        // Loop through all gradients and generate the svg.
        for (uint256 i; i < honeycomb.grid.totalGradients; ) {
            GradientStop memory stop;

            // Get next stop.
            if (stopCount < honeycomb.gradients.chrome) {
                stop = getLinearGradientStopSvg(honeycomb, stopCount);
                stops[stopCount] = stop;
                unchecked {
                    ++stopCount;
                }
            } else {
                // Randomly select a stop from existing ones.
                stop = stops[
                    Utilities.random(honeycomb.seed, abi.encodePacked("stop", Utilities.uint2str(i)), stopCount)
                ];
            }

            // Get gradients svg based on the base hexagon type.
            if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
                GradientData memory gradientData;
                gradientData.stop1 = prevStop;
                gradientData.stop2 = stop;
                gradientData.duration = honeycomb.gradients.duration;
                gradientData.gradientId = uint8(i + 1);
                gradientData.y1 = 25;
                gradientData.y2 = 81;
                gradientData.offset = 72;
                bytes memory gradientSvg = getLinearGradientSvg(gradientData);

                // Append gradient to svg, update previous stop, and increment index.
                svg = abi.encodePacked(svg, gradientSvg);
                prevStop = stop;
                unchecked {
                    ++i;
                }
            } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
                // Flat tops require two gradients.
                GradientData memory gradientData1;
                gradientData1.stop1 = prevStop;
                gradientData1.stop2 = stop;
                gradientData1.duration = honeycomb.gradients.duration;
                gradientData1.gradientId = uint8(i + 1);
                gradientData1.y1 = 50;
                gradientData1.y2 = 100;
                gradientData1.offset = 72;
                bytes memory gradient1Svg = getLinearGradientSvg(gradientData1);

                if (i == honeycomb.grid.totalGradients - 1) {
                    // If this is the last gradient, we don't need to generate the second gradient.
                    svg = abi.encodePacked(svg, gradient1Svg);
                    break;
                }

                GradientData memory gradientData2;
                gradientData2.stop1 = prevStop;
                gradientData2.stop2 = stop;
                gradientData2.duration = honeycomb.gradients.duration;
                gradientData2.gradientId = uint8(i + 2);
                gradientData2.y1 = 4;
                gradientData2.y2 = 100;
                gradientData2.offset = 30;
                bytes memory gradient2Svg = getLinearGradientSvg(gradientData2);

                // Append both gradients to svg, update previous stop, and increment index.
                svg = abi.encodePacked(svg, gradient1Svg, gradient2Svg);
                prevStop = stop;
                unchecked {
                    i += 2;
                }
            }
        }

        return svg;
    }
}

/// @dev All internal data relevant to a gradient stop.
struct GradientStop {
    bytes color; // color of the gradient stop
    bytes animationColorValues; // color values for the animation
}

/// @dev All additional internal data for rendering a gradient svg string.
struct GradientData {
    GradientStop stop1; // first gradient stop
    GradientStop stop2; // second gradient stop
    uint16 duration; // duration of the animation
    uint8 gradientId; // id of the gradient
    uint8 y1; // y1 of the gradient
    uint8 y2; // y2 of the gradient
    uint8 offset; // offset of the gradient
}
