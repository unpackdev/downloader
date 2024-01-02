// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity 0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(int256 a, int256 b) internal pure returns (int256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(int256 a, int256 b) internal pure returns (int256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
