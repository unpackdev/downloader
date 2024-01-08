// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./LowGasSafeMath.sol";


library Fraction {
  using LowGasSafeMath for uint256;

  uint256 internal constant ONE_E18 = 1e18;

  function mulFractionE18(uint256 a, uint256 fraction) internal pure returns (uint256) {
    return a.mul(fraction) / ONE_E18;
  }

  function mulSubFractionE18(uint256 a, uint256 fraction) internal pure returns (uint256) {
    return a.sub(a.mul(fraction) / ONE_E18);
  }

  function toFractionE18(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(ONE_E18) / b;
  }
}