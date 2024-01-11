// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library UnsafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a + b;
    }
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a - b;
    }
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a * b;
    }
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a / b;
    }
  }
}
