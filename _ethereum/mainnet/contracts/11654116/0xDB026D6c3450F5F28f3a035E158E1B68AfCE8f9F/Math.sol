// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }
}
