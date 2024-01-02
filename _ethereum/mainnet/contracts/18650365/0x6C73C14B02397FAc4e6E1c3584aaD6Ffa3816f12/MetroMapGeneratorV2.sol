// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        888
//                        888
//                        888
// 88888b.d88b.   .d88b.  888888 888d888 .d88b.
// 888 "888 "88b d8P  Y8b 888    888P"  d88""88b
// 888  888  888 88888888 888    888    888  888
// 888  888  888 Y8b.     Y88b.  888    Y88..88P
// 888  888  888  "Y8888   "Y888 888     "Y88P"

// 888                    d8b          888                          888
// 888                    Y8P          888                          888
// 888                                 888                          888
// 88888b.  888  888      888 88888b.  888888       8888b.  888d888 888888
// 888 "88b 888  888      888 888 "88b 888             "88b 888P"   888
// 888  888 888  888      888 888  888 888         .d888888 888     888
// 888 d88P Y88b 888      888 888  888 Y88b.       888  888 888     Y88b.
// 88888P"   "Y88888      888 888  888  "Y888      "Y888888 888      "Y888
//               888
//          Y8b d88P
//           "Y88P"

import "./Ownable.sol";

import "./IMetroMapGeneratorV2.sol";
import "./IMetro.sol";
import "./MetroThemeStorageV2.sol";

import "./LibString.sol";
import "./LibPRNG.sol";
import "./DynamicBuffer.sol";

contract MetroMapGeneratorV2 is Ownable, IMetroMapGeneratorV2 {
    using DynamicBuffer for bytes;

    struct Boundry {
        MetroStop left;
        MetroStop right;
        MetroStop top;
        MetroStop bottom;
        MetroStop topLeft;
        MetroStop topRight;
        MetroStop bottomLeft;
        MetroStop bottomRight;
    }

    struct Properties {
        uint256 seed;
        uint256 progress;
        uint256 progressSeedStep;
        uint256 stopCount;
        uint256 lineCount;
        uint256 colorOffset;
        MetroThemeV2 theme;
        Boundry boundry;
        LibPRNG.PRNG random;
        bytes32[] progressSeeds;
    }

    struct LineRequest {
        uint256 stopCount;
        uint256 baseDirection;
        MetroStop base;
        Properties properties;
        uint256[] baseMetroStopDirections;
        bytes svgBytes;
    }

    struct LineGroupRequest {
        uint256 lineCount;
        bool shouldExtendALine;
        MetroStop base;
        Properties properties;
        bytes svgBytes;
    }

    struct MapOffset {
        bool isXNegative;
        bool isYNegative;
        uint256 x;
        uint256 y;
        uint256 scale;
    }

    uint256 constant GRID_SIZE = 20;

    // We don't know the size of SVG buffer size beforehand.
    // During tests 50k was more than enough. It's upgrable
    // just in case.
    uint256 public SVGBufferAllocation = 50000;

    function updateSVGBufferAllocation(
        uint256 _SVGBufferAllocation
    ) public onlyOwner {
        SVGBufferAllocation = _SVGBufferAllocation;
    }

    function generateMap(
        MetroTokenProperties memory tokenProperties,
        MetroThemeV2 memory theme,
        uint256 tokenId,
        uint256 mode
    ) public view returns (MetroMapResult memory) {
        unchecked {
            MetroStop memory base;
            base.x = 10000;
            base.y = 10000;

            Properties memory properties;
            properties.seed = uint256(tokenProperties.seed);
            properties.colorOffset = uint256(tokenProperties.seed) % 20;
            properties.progress = tokenProperties.progress;
            properties.progressSeedStep = tokenProperties.progressSeedStep;
            properties.progressSeeds = tokenProperties.progressSeeds;
            properties.theme = theme;
            LibPRNG.seed(properties.random, properties.seed);

            // SVG data is generated only when mode = 1
            bytes memory svgBytes;
            if (mode == 1) {
                svgBytes = DynamicBuffer.allocate(SVGBufferAllocation);

                svgBytes.appendSafe(
                    "<svg width='100%' height='100%' viewBox='0 0 20000 20000' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><style>.t{font: bold 900px sans-serif;fill:"
                );
                svgBytes.appendSafe(theme.mTextColor);
                svgBytes.appendSafe("}.d{font: bold 400px sans-serif;fill:");
                svgBytes.appendSafe(theme.mTextColor);
                svgBytes.appendSafe(
                    "}</style><symbol id='group' stroke-width='12' stroke-linecap='round' stroke-join='round' fill='transparent'>"
                );
            }

            uint256 groupCount = tokenProperties.progress + 1;
            MetroLineGroup[] memory groups = new MetroLineGroup[](groupCount);

            uint256 i;
            do {
                randomiseSeedIfNeeded(properties, i);

                MetroLineGroup memory lineGroup;
                uint256 lineCount;

                if (i == 0) {
                    lineCount = randomBetween(properties, 1, 5);
                    LineGroupRequest memory groupRequest;
                    groupRequest.properties = properties;
                    groupRequest.base = base;
                    groupRequest.lineCount = lineCount;
                    groupRequest.svgBytes = svgBytes;

                    lineGroup = generateLineGroups(groupRequest);
                } else {
                    lineCount = randomBetween(properties, 3, 5);

                    uint256 cornerIndex = randomUniform(properties, 4);

                    MetroStop memory groupBase;

                    if (cornerIndex == 0) {
                        groupBase = properties.boundry.top;
                    } else if (cornerIndex == 1) {
                        groupBase = properties.boundry.left;
                    } else if (cornerIndex == 2) {
                        groupBase = properties.boundry.right;
                    } else if (cornerIndex == 3) {
                        groupBase = properties.boundry.bottom;
                    }

                    LineGroupRequest memory groupRequest;
                    groupRequest.properties = properties;
                    groupRequest.base = groupBase;
                    groupRequest.lineCount = lineCount;
                    groupRequest.svgBytes = svgBytes;
                    lineGroup = generateLineGroups(groupRequest);
                }

                groups[i] = lineGroup;
            } while (++i < groupCount);

            MetroMapResult memory result;
            result.lineCount = properties.lineCount;
            result.stopCount = properties.stopCount;

            if (mode == 0) {
                result.lineGroups = groups;
                return result;
            }

            MapOffset memory mapOffset = calculateMapOffset(
                base,
                properties.boundry,
                tokenProperties.progress
            );

            svgBytes.appendSafe(
                "</symbol><defs><pattern id='tenthGrid' width='100' height='100' patternUnits='userSpaceOnUse'><path d='M 100 0 L 0 0 0 100' fill='none' stroke='black' opacity='0.1' stroke-width='10'/></pattern><pattern id='grid' width='1000' height='1000' patternUnits='userSpaceOnUse'><rect width='1000' height='1000' fill='url(#tenthGrid)'/><path d='M 1000 0 L 0 0 0 1000' fill='none' stroke='black' opacity='0.15' stroke-width='20'/></pattern></defs>"
            );
            svgBytes.appendSafe(
                "<rect width='100%' height='100%' opacity='1' fill='"
            );
            svgBytes.appendSafe(theme.mBackgroundColor);
            svgBytes.appendSafe(
                "'/><g stroke-width='40' x='20%' y='10%' width='60%' height='80%' fill='"
            );

            bytes memory backgroundColor = theme.backgroundColor;
            if (theme.pBackgroundColor.length > 0) {
                backgroundColor = theme.pBackgroundColor;
            }

            svgBytes.appendSafe(backgroundColor);
            svgBytes.appendSafe("' stroke='");
            svgBytes.appendSafe(theme.mBorderColor);

            if (tokenProperties.progress < 15) {
                svgBytes.appendSafe(
                    "'><rect x='20%' y='10%' width='60%' height='80%'/></g><rect x='20%' y='10%' width='60%' height='80%' fill='url(#grid)'/><text x='22%' y='15.8%' class='t'>"
                );
            } else if (tokenProperties.progress < 35) {
                svgBytes.appendSafe(
                    "'><rect x='20%' y='10%' width='60%' height='80%' transform='rotate(5, 6000, 6000)'/><rect x='20%' y='10%' width='60%' height='80%'/></g><rect x='20%' y='10%' width='60%' height='80%' fill='url(#grid)'/><text x='22%' y='15.8%' class='t'>"
                );
            } else {
                svgBytes.appendSafe(
                    "'><rect x='20%' y='10%' width='60%' height='80%' transform='rotate(-3, 6000, 6000)'/><rect x='20%' y='10%' width='60%' height='80%' transform='rotate(5, 6000, 6000)'/><rect x='20%' y='10%' width='60%' height='80%'/></g><rect x='20%' y='10%' width='60%' height='80%' fill='url(#grid)'/><text x='22%' y='15.8%' class='t'>"
                );
            }

            svgBytes.appendSafe("METRO Plan #");
            svgBytes.appendSafe(bytes(LibString.toString(tokenId)));

            if (tokenProperties.progress == 50) {
                svgBytes.appendSafe(
                    "</text><text x='22%' y='19%' class='d'>// complete</text>"
                );
            } else if (tokenProperties.mode == 2) {
                svgBytes.appendSafe(
                    "</text><text x='22%' y='19%' class='d'>// construction stopped</text>"
                );
            } else if (tokenProperties.mode == 1) {
                svgBytes.appendSafe(
                    "</text><text x='22%' y='19%' class='d'>// under construction</text>"
                );
            } else {
                svgBytes.appendSafe(
                    "</text><text x='22%' y='19%' class='d'>// under review</text>"
                );
            }

            bytes memory mapScale = bytes(LibString.toString(mapOffset.scale));
            svgBytes.appendSafe("<style>.g {transform: scale(");
            svgBytes.appendSafe(mapScale);
            svgBytes.appendSafe(", ");
            svgBytes.appendSafe(mapScale);
            svgBytes.appendSafe(
                ");}</style><g transform-origin='center' class='g'><use xlink:href='#group' transform='translate("
            );

            if (mapOffset.isXNegative) {
                svgBytes.appendSafe("-");
            }

            svgBytes.appendSafe(bytes(LibString.toString(mapOffset.x)));

            if (mapOffset.isYNegative) {
                svgBytes.appendSafe(" -");
            } else {
                svgBytes.appendSafe(" ");
            }

            svgBytes.appendSafe(bytes(LibString.toString(mapOffset.y)));
            svgBytes.appendSafe(")'/></g></svg>");
            result.svg = svgBytes;
            return result;
        }
    }

    function generateLineGroups(
        LineGroupRequest memory groupRequest
    ) public pure returns (MetroLineGroup memory) {
        unchecked {
            MetroLine[] memory lines = new MetroLine[](groupRequest.lineCount);

            uint256 stopCount;
            uint256 midIndex = groupRequest.lineCount / 3;

            uint256 i;
            uint256 length = groupRequest.lineCount;
            do {
                MetroLine memory line;
                if (i == 0) {
                    stopCount = randomBetween(groupRequest.properties, 3, 5);
                } else {
                    stopCount = randomBetween(groupRequest.properties, 3, 12);
                }

                LineRequest memory lineRequest;
                lineRequest.base = groupRequest.base;
                lineRequest.properties = groupRequest.properties;
                lineRequest.stopCount = stopCount;
                lineRequest.svgBytes = groupRequest.svgBytes;

                if (i > 0) {
                    uint256 lineIndex = randomUniform(
                        groupRequest.properties,
                        i
                    );

                    MetroLine memory randomLine = lines[lineIndex];

                    uint256 stopIndex = randomUniform(
                        groupRequest.properties,
                        randomLine.stops.length
                    );

                    lineRequest.base = randomLine.stops[stopIndex];
                    lineRequest.baseMetroStopDirections = randomLine
                        .stopDirections;
                    if (i > midIndex) {
                        lineRequest.baseMetroStopDirections = randomLine
                            .stopDirections;
                    }
                }

                line = generateLine(lineRequest);
                lines[i] = line;
            } while (++i < length);

            MetroLineGroup memory group;
            group.lines = lines;
            return group;
        }
    }

    function generateLine(
        LineRequest memory lineRequest
    ) public pure returns (MetroLine memory) {
        unchecked {
            MetroLine memory line;
            line.stops = new MetroStop[](lineRequest.stopCount);
            line.stopDirections = new uint256[](lineRequest.stopCount);

            MetroStop memory previousMetroStop;

            uint256 direction = randomUniform(lineRequest.properties, 8);
            uint256 maxDirectionChange = 6;
            uint256 directChangeCount;

            lineRequest.svgBytes.appendSafe("<path d='M");

            uint256 i;
            uint256 length = lineRequest.stopCount;
            do {
                MetroStop memory nextMetroStop;
                if (i == 0) {
                    nextMetroStop = lineRequest.base;
                } else {
                    nextMetroStop = getNextMetroStop(
                        previousMetroStop,
                        direction
                    );
                }
                previousMetroStop = nextMetroStop;

                line.stops[i] = nextMetroStop;
                line.stopDirections[i] = direction;

                uint256 directionChange = randomBetween(
                    lineRequest.properties,
                    0,
                    13
                );

                if (directChangeCount < maxDirectionChange) {
                    if (
                        lineRequest.baseMetroStopDirections.length > 0 &&
                        i < lineRequest.baseMetroStopDirections.length - 1
                    ) {
                        uint256 previousDirection = direction;
                        uint256 nextDirection = lineRequest
                            .baseMetroStopDirections[i + 1];
                        if (previousDirection != nextDirection) {
                            directChangeCount++;
                        }
                        direction = nextDirection;
                    } else {
                        if (directionChange > 0 && directionChange < 5) {
                            direction++;
                            if (direction > 7) {
                                direction = direction % 8;
                            }
                            directChangeCount++;
                        } else if (
                            directionChange > 4 && directionChange < 10
                        ) {
                            if (direction == 0) {
                                direction = 7;
                            } else {
                                direction--;
                            }
                            directChangeCount++;
                        }
                    }
                }

                compareMetroStopWithBoundry(
                    nextMetroStop,
                    lineRequest.properties.boundry
                );

                lineRequest.svgBytes.appendSafe(
                    bytes(LibString.toString(nextMetroStop.x))
                );
                lineRequest.svgBytes.appendSafe(" ");
                lineRequest.svgBytes.appendSafe(
                    bytes(LibString.toString(nextMetroStop.y))
                );
                if (i < lineRequest.stopCount - 1) {
                    lineRequest.svgBytes.appendSafe(" ");
                }
                lineRequest.properties.stopCount++;
            } while (++i < length);

            lineRequest.svgBytes.appendSafe("' stroke='");
            lineRequest.svgBytes.appendSafe(
                getLineColor(lineRequest.properties)
            );
            lineRequest.svgBytes.appendSafe("'/>");
            lineRequest.properties.lineCount++;

            return line;
        }
    }

    function getNextMetroStop(
        MetroStop memory currentMetroStop,
        uint256 direction
    ) internal pure returns (MetroStop memory) {
        unchecked {
            MetroStop memory nextMetroStop;
            if (direction == 0) {
                nextMetroStop.x = currentMetroStop.x + GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y;
            } else if (direction == 1) {
                nextMetroStop.x = currentMetroStop.x + GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y + GRID_SIZE;
            } else if (direction == 2) {
                nextMetroStop.x = currentMetroStop.x;
                nextMetroStop.y = currentMetroStop.y + GRID_SIZE;
            } else if (direction == 3) {
                nextMetroStop.x = currentMetroStop.x - GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y + GRID_SIZE;
            } else if (direction == 4) {
                nextMetroStop.x = currentMetroStop.x - GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y;
            } else if (direction == 5) {
                nextMetroStop.x = currentMetroStop.x - GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y - GRID_SIZE;
            } else if (direction == 6) {
                nextMetroStop.x = currentMetroStop.x;
                nextMetroStop.y = currentMetroStop.y - GRID_SIZE;
            } else if (direction == 7) {
                nextMetroStop.x = currentMetroStop.x + GRID_SIZE;
                nextMetroStop.y = currentMetroStop.y - GRID_SIZE;
            }
            return nextMetroStop;
        }
    }

    function calculateMapOffset(
        MetroStop memory base,
        Boundry memory mapBoundry,
        uint256 progress
    ) internal pure returns (MapOffset memory) {
        unchecked {
            MapOffset memory mapOffset;

            uint256 width = mapBoundry.right.x - mapBoundry.left.x;
            uint256 height = mapBoundry.bottom.y - mapBoundry.top.y;

            uint256 centerOffsetX = base.x - mapBoundry.left.x;
            uint256 centerOffsetY = base.y - mapBoundry.top.y;

            uint256 mapSize;
            if (width > height) {
                mapSize = width;
            } else {
                mapSize = height;
            }

            if (progress < 5) {
                mapOffset.scale = 5000 / mapSize;
            } else if (progress < 10) {
                mapOffset.scale = 8000 / mapSize;
            } else {
                mapOffset.scale = 11000 / mapSize;
            }

            if (width / 2 > centerOffsetX) {
                mapOffset.x = (width / 2) - centerOffsetX;
                mapOffset.isXNegative = true;
            } else {
                mapOffset.x = centerOffsetX - (width / 2);
            }

            if (height / 2 > centerOffsetY) {
                mapOffset.y = (height / 2) - centerOffsetY;
                mapOffset.isYNegative = true;
            } else {
                mapOffset.y = centerOffsetY - (height / 2);
            }

            return mapOffset;
        }
    }

    function compareMetroStopWithBoundry(
        MetroStop memory point,
        Boundry memory boundry
    ) internal pure {
        unchecked {
            if (point.x < boundry.left.x || boundry.left.x == 0) {
                boundry.left = point;
            }
            if (point.x > boundry.right.x || boundry.right.x == 0) {
                boundry.right = point;
            }
            if (point.y < boundry.top.y || boundry.top.y == 0) {
                boundry.top = point;
            }
            if (point.y >= boundry.bottom.y || boundry.bottom.y == 0) {
                boundry.bottom = point;
            }

            if (point.x <= boundry.left.x && point.y <= boundry.top.y) {
                boundry.topLeft = point;
            }
            if (point.x >= boundry.right.x && point.y <= boundry.top.y) {
                boundry.topRight = point;
            }
            if (point.x <= boundry.left.x && point.y >= boundry.bottom.y) {
                boundry.bottomLeft = point;
            }
            if (point.x >= boundry.right.x && point.y >= boundry.bottom.y) {
                boundry.bottomRight = point;
            }
        }
    }

    function randomiseSeedIfNeeded(
        Properties memory properties,
        uint256 groupIndex
    ) internal pure {
        unchecked {
            uint256 progressIndex = groupIndex / properties.progressSeedStep;

            if (progressIndex == 0) {
                return;
            }
            uint256 progressSeed;

            if (progressIndex < properties.progressSeeds.length) {
                progressSeed = uint256(properties.progressSeeds[progressIndex]);
                if (properties.seed != progressSeed) {
                    properties.seed = progressSeed;
                    LibPRNG.seed(properties.random, progressSeed);
                }
            }
        }
    }

    function randomUniform(
        Properties memory properties,
        uint256 max
    ) internal pure returns (uint256) {
        unchecked {
            return LibPRNG.uniform(properties.random, max);
        }
    }

    function randomBetween(
        Properties memory properties,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256) {
        unchecked {
            return min + LibPRNG.uniform(properties.random, max - min);
        }
    }

    function getLineColor(
        Properties memory properties
    ) internal pure returns (bytes memory) {
        return
            properties.theme.lineColors[
                (properties.lineCount + properties.colorOffset) %
                    properties.theme.lineColors.length
            ];
    }
}
