// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./Utils.sol";
import "./Trigonometry.sol";
import "./SVG.sol";
import "./LibPRNG.sol";
import "./LibString.sol";

/// @title ColorfulArt
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice ColorfulArt provides utility functions for creating colorful polygon art
contract ColorfulArt {
  using LibPRNG for LibPRNG.PRNG;
  using LibString for uint256;

  struct Point {
    // Scale by 1e18
    uint256 x;
    uint256 y;
  }

  uint16 internal constant MAX_POINTS_TOTAL = 1000;
  uint24[MAX_POINTS_TOTAL + 1] internal tokenToColor;
  uint24[MAX_POINTS_TOTAL + 1] internal tokenToBackgroundColor;

  uint8 internal constant MAX_POINTS_PER_POLYGON = 100;
  uint8 private constant LINE_WIDTH = 10;
  uint8 private constant MAX_RADIUS = 120;
  bool internal commenced;

  function polarToCartesian(uint256 radius, uint256 angleInDegrees) internal pure returns (Point memory) {
    int256 angleInRadians = ((int256(angleInDegrees)) * int256(Trigonometry.PI)) /
      (180.0 * 1e18) +
      // Add 2 PI to ensure radians is always positive
      int256(
        Trigonometry.TWO_PI -
          // Rotate 90 degrees counterclockwise
          Trigonometry.PI /
          2.0
      );

    return
      // Point has both x and y scaled by 1e18
      Point({
        x: uint256(
          int256(
            // Scale by 1e18
            200 * 1e18
          ) + ((int256(radius) * Trigonometry.cos(uint256(angleInRadians))))
        ),
        y: uint256(
          int256(
            // Scale by 1e18
            200 * 1e18
          ) + ((int256(radius) * Trigonometry.sin(uint256(angleInRadians))))
        )
      });
  }

  function getDecimalStringFrom1e18ScaledUint256(uint256 scaled) internal pure returns (string memory decimal) {
    uint256 partBeforeDecimal = scaled / 1e18;
    uint256 partAfterDecimal = (scaled % 1e18);
    if (partAfterDecimal > 1e17) {
      // Throw out last 12 digits, as that much precision is unnecessary and bloats the string size
      partAfterDecimal = partAfterDecimal / 1e12;
    }
    return string.concat(partBeforeDecimal.toString(), ".", partAfterDecimal.toString());
  }

  function polygon(uint256 radius, uint16 numPoints) internal pure returns (Point[] memory points) {
    points = new Point[](numPoints);

    // Degrees scaled by 1e18 for precision
    unchecked {
      uint256 degreeIncrement = (360 * 1e18) / numPoints;
      for (uint32 i; i < numPoints; ++i) {
        uint256 angleInDegrees = degreeIncrement * i;
        points[i] = polarToCartesian(radius, angleInDegrees);
      }
    }
  }

  function linesSvgFromPoints(
    Point[] memory points,
    uint16 startColorIdx,
    // This is the token id
    uint16 pointWithIdIdx
  ) internal view returns (string memory linesSvg) {
    if (points.length == 1) {
      // Return a dot in the center
      return
        svg.line(
          string.concat(
            svg.prop("x1", "200"),
            svg.prop("y1", "200"),
            svg.prop("x2", "200"),
            svg.prop("y2", "200"),
            svg.prop("stroke-linecap", "round"),
            svg.prop("stroke", Utils.getRGBStr(tokenToColor[startColorIdx])),
            svg.prop("id", "m")
          )
        );
    }

    unchecked {
      for (uint16 i; i < points.length; ++i) {
        bool isEnd = i + 1 == points.length;
        uint32 colorIdx = i + startColorIdx;
        linesSvg = string.concat(
          linesSvg,
          svg.line(
            string.concat(
              svg.prop("x1", getDecimalStringFrom1e18ScaledUint256(points[i].x)),
              svg.prop("y1", getDecimalStringFrom1e18ScaledUint256(points[i].y)),
              svg.prop("x2", getDecimalStringFrom1e18ScaledUint256(isEnd ? points[0].x : points[i + 1].x)),
              svg.prop("y2", getDecimalStringFrom1e18ScaledUint256(isEnd ? points[0].y : points[i + 1].y)),
              svg.prop("stroke", Utils.getRGBStr(tokenToColor[colorIdx])),
              pointWithIdIdx == colorIdx ? svg.prop("id", "m") : ""
            )
          )
        );
      }
    }
  }

  function art(uint16 numberOfPoints) public view returns (string memory) {
    if (!commenced) {
      return "";
    }

    string memory lines;

    unchecked {
      uint256 fullPolygonsCount = numberOfPoints / MAX_POINTS_PER_POLYGON;

      for (uint8 i; i < fullPolygonsCount; ++i) {
        Point[] memory polyPoints = polygon(MAX_RADIUS - i * LINE_WIDTH, MAX_POINTS_PER_POLYGON);
        lines = string.concat(
          lines,
          linesSvgFromPoints(polyPoints, uint16(i * MAX_POINTS_PER_POLYGON + 1), numberOfPoints)
        );
      }

      uint16 remainingPoints = numberOfPoints % MAX_POINTS_PER_POLYGON;

      if (remainingPoints > 0) {
        lines = string.concat(
          lines,
          linesSvgFromPoints(
            polygon(uint16(MAX_RADIUS - fullPolygonsCount * LINE_WIDTH), remainingPoints),
            uint16(fullPolygonsCount * MAX_POINTS_PER_POLYGON + 1),
            numberOfPoints
          )
        );
      }
    }

    return
      string.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 400 400" style="background:',
        Utils.getRGBStr(tokenToBackgroundColor[numberOfPoints]),
        ';display:block;margin:auto"><style>line{stroke-width:10;}</style>',
        lines,
        "</svg>"
      );
  }
}
