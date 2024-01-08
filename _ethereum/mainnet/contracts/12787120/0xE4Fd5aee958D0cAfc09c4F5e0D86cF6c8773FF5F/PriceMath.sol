// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import "./TickMath.sol";
import "./UnsafeMath.sol";

/// @title Math library for computing sqrt prices from price and vice versa.
/// @notice Computes sqrt price for price.
library PriceMath {
  function sqrt(uint256 x) internal pure returns (uint256 y) {
    uint256 z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  /// @notice Calculates the sqrt ratio for given price
  /// @param token0 The address of token0
  /// @param token1 The address of token1
  /// @param price The amount with decimals of token1 for 1 token0
  /// @return sqrtPriceX96 The greatest tick for which the ratio is less than or equal to the input ratio
  function getSqrtRatioAtPrice(
    address token0,
    address token1,
    uint256 price
  ) internal pure returns (uint160 sqrtPriceX96) {
    uint256 base = 1e18;
    if (token0 > token1) {
      (token0, token1) = (token1, token0);
      (base, price) = (price, base);
    }
    uint256 priceX96 = (price << 192) / base;
    sqrtPriceX96 = uint160(sqrt(priceX96));
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param token0 The address of token0
  /// @param token1 The address of token1
  /// @param sqrtPriceX96 The sqrt ratio for which to compute the price as a Q64.96
  /// @return price The amount with decimals of token1 for 1 token0
  function getPriceAtSqrtRatio(
    address token0,
    address token1,
    uint160 sqrtPriceX96
  ) internal pure returns (uint256 price) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtPriceX96 >= TickMath.MIN_SQRT_RATIO && sqrtPriceX96 < TickMath.MAX_SQRT_RATIO, 'R');

    uint256 base = 1e18;
    uint256 priceX96 = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
    if (token0 > token1) {
      price = UnsafeMath.divRoundingUp(base << 192, priceX96);
    } else {
      price = (priceX96 * base) >> 192;
    }
  }
}
