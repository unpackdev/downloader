// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library PercentageMath {
  ///	CONSTANTS ///

  uint256 internal constant PERCENTAGE_FACTOR = 1e4; // 100.00%
  uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4; // 50.00%
  uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
  uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE = 2 ** 256 - 1 - 0.5e4;

  /// INTERNAL ///

  ///@notice Check if value are within the range
  function _isInRange(uint256 valA, uint256 valB, uint256 deviationThreshold)
    internal
    pure
    returns (bool)
  {
    uint256 lowerBound = percentSub(valA, deviationThreshold);
    uint256 upperBound = percentAdd(valA, deviationThreshold);
    if (valB < lowerBound || valB > upperBound) return false;
    else return true;
  }

  /// @notice Executes a percentage addition (x * (1 + p)), rounded up.
  /// @param x The value to which to add the percentage.
  /// @param percentage The percentage of the value to add.
  /// @return y The result of the addition.
  function percentAdd(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
    // Must revert if
    // PERCENTAGE_FACTOR + percentage > type(uint256).max
    //     or x * (PERCENTAGE_FACTOR + percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
    // <=> percentage > type(uint256).max - PERCENTAGE_FACTOR
    //     or x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + percentage)
    // Note: PERCENTAGE_FACTOR + percentage >= PERCENTAGE_FACTOR > 0
    assembly {
      y := add(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

      if or(
        gt(percentage, sub(MAX_UINT256, PERCENTAGE_FACTOR)),
        gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y))
      ) { revert(0, 0) }

      y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
    }
  }

  /// @notice Executes a percentage subtraction (x * (1 - p)), rounded up.
  /// @param x The value to which to subtract the percentage.
  /// @param percentage The percentage of the value to subtract.
  /// @return y The result of the subtraction.
  function percentSub(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
    // Must revert if
    // percentage > PERCENTAGE_FACTOR
    //     or x * (PERCENTAGE_FACTOR - percentage) + HALF_PERCENTAGE_FACTOR > type(uint256).max
    // <=> percentage > PERCENTAGE_FACTOR
    //     or ((PERCENTAGE_FACTOR - percentage) > 0 and x > (type(uint256).max -
    // HALF_PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR - percentage))
    assembly {
      y := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

      if or(
        gt(percentage, PERCENTAGE_FACTOR), mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, y)))
      ) { revert(0, 0) }

      y := div(add(mul(x, y), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
    }
  }
}
