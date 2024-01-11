// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library MathUtil {
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 m = a % b;
    uint256 r = (a - m) / b;
    if (m > 0) {
      r += 1;
    }

    return r;
  }
}
