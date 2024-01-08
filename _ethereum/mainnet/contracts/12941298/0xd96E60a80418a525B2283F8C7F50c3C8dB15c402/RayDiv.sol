// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
import "./LowGasSafeMath.sol";


library RayDiv {
  using LowGasSafeMath for uint256;
  uint256 internal constant RAY = 1e27;


  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;
    return halfB.add(a.mul(RAY)) / b;
  }
}