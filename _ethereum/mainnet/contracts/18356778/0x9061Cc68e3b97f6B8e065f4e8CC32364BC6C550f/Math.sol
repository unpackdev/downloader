// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Solidity library offering basic functions where inputs and outputs are
 * integers. Inputs are specified in units scaled by 1e18, and similarly outputs are scaled by 1e18.
 */

library Math {

  /**
   * Returns the square root of a number scaled by 1e18
   * Sourced from uniswap v2 on
   * https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
   * and adapted for 1e18 numbers.
   */
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }

    z *= 1e9;
  }

  /**
   * Simple abs function
   */
  function abs(int x) internal pure returns (uint) {
    if(x < 0) {
      return uint(- x);
    }
    return uint(x);
  }

  /**
   * Floor a number scaled by 1e18
   */
  function floor(int x) internal pure returns (int) {
    if(x < 0) {
      return x - (x % 1e18 + 1e18);
    }
    return x - x % 1e18;
  }

  function round(int x) internal pure returns (int) {
    int part = x % 1e18;
    if(x > 0 && part >= 1e18 / 2) {
      return x - part + 1e18;
    }
    if(x < 0 && part <= - 1e18 / 2) {
      return x - part - 1e18;
    }
    return x - part;
  }

  /**
   *  Round down a 1e18-scaled number:
   * 4.50001 => 5
   * 4.5 => 4
   * 4.49999 => 4
   */
  function roundDown(int x) internal pure returns (int) {
    int part = x % 1e18;
    if(x > 0 && part > 1e18 / 2) {
      return x - part + 1e18;
    }
    if(x < 0 && part < - 1e18 / 2) {
      return x - part - 1e18;
    }
    return x - part;
  }
}