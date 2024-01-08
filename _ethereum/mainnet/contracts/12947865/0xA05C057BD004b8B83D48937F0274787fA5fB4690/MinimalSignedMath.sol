// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;


library MinimalSignedMath {
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

    return c;
  }

  function add(uint256 a, int256 b) internal pure returns (uint256) {
    require(a < 2**255);
    int256 _a = int256(a);
    int256 c = _a + b;
    require((b >= 0 && c >= _a) || (b < 0 && c < _a));
    if (c < 0) return 0;
    return uint256(c);
  }
}