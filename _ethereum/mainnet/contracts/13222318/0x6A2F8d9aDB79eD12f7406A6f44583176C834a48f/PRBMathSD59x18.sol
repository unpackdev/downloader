// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
  /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
  int256 internal constant LOG2_E = 1442695040888963407;

  /// @dev Half the SCALE number.
  int256 internal constant HALF_SCALE = 5e17;

  /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MAX_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728792003956564819967;

  /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MAX_WHOLE_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728000000000000000000;

  /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MIN_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728792003956564819968;

  /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
  int256 internal constant MIN_WHOLE_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728000000000000000000;

  /// @dev How many trailing decimals can be represented.
  int256 internal constant SCALE = 1e18;

  /// INTERNAL FUNCTIONS ///

  /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
  ///
  /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
  ///
  /// Requirements:
  /// - All from "PRBMath.mulDiv".
  /// - None of the inputs can be MIN_SD59x18.
  /// - The denominator cannot be zero.
  /// - The result must fit within int256.
  ///
  /// Caveats:
  /// - All from "PRBMath.mulDiv".
  ///
  /// @param x The numerator as a signed 59.18-decimal fixed-point number.
  /// @param y The denominator as a signed 59.18-decimal fixed-point number.
  /// @param result The quotient as a signed 59.18-decimal fixed-point number.
  function div(int256 x, int256 y) internal pure returns (int256 result) {
    require(
      !(x == MIN_SD59x18 || y == MIN_SD59x18),
      "PRBMathSD59x18__DivInputTooSmall"
    );

    // Get hold of the absolute values of x and y.
    uint256 ax;
    uint256 ay;
    unchecked {
      ax = x < 0 ? uint256(-x) : uint256(x);
      ay = y < 0 ? uint256(-y) : uint256(y);
    }

    // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
    uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
    require(!(rAbs > uint256(MAX_SD59x18)), "PRBMathSD59x18__DivOverflow");

    // Get the signs of x and y.
    uint256 sx;
    uint256 sy;
    assembly {
      sx := sgt(x, sub(0, 1))
      sy := sgt(y, sub(0, 1))
    }

    // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
    // should be positive. Otherwise, it should be negative.
    result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
  }

  /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
  /// of the radix point for negative numbers.
  /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
  /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
  /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
  function frac(int256 x) internal pure returns (int256 result) {
    unchecked {
      result = x % SCALE;
    }
  }

  /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
  ///
  /// @dev Requirements:
  /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
  /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
  ///
  /// @param x The basic integer to convert.
  /// @param result The same number in signed 59.18-decimal fixed-point representation.
  function fromInt(int256 x) internal pure returns (int256 result) {
    unchecked {
      require(!(x < MIN_SD59x18 / SCALE), "PRBMathSD59x18__FromIntUnderflow");
      require(!(x > MAX_SD59x18 / SCALE), "PRBMathSD59x18__FromIntOverflow");
      result = x * SCALE;
    }
  }

  /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
  /// fixed-point number.
  ///
  /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
  /// always 1e18.
  ///
  /// Requirements:
  /// - All from "PRBMath.mulDivFixedPoint".
  /// - None of the inputs can be MIN_SD59x18
  /// - The result must fit within MAX_SD59x18.
  ///
  /// Caveats:
  /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
  ///
  /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
  /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
  /// @return result The product as a signed 59.18-decimal fixed-point number.
  function mul(int256 x, int256 y) internal pure returns (int256 result) {
    require(
      !(x == MIN_SD59x18 || y == MIN_SD59x18),
      "PRBMathSD59x18__MulInputTooSmall"
    );

    unchecked {
      uint256 ax;
      uint256 ay;
      ax = x < 0 ? uint256(-x) : uint256(x);
      ay = y < 0 ? uint256(-y) : uint256(y);

      uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
      require(!(rAbs > uint256(MAX_SD59x18)), "PRBMathSD59x18__MulOverflow");

      uint256 sx;
      uint256 sy;
      assembly {
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
      }
      result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }
  }

  /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
  function pi() internal pure returns (int256 result) {
    result = 3141592653589793238;
  }

  /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
  function scale() internal pure returns (int256 result) {
    result = SCALE;
  }

  /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
  /// @param x The signed 59.18-decimal fixed-point number to convert.
  /// @return result The same number in basic integer form.
  function toInt(int256 x) internal pure returns (int256 result) {
    unchecked {
      result = x / SCALE;
    }
  }
}
