// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMathUpgradeable.sol";

library ListsLib {
  using SafeMath for *;
  function sum(uint256[] memory list) internal pure returns (uint256 result) {
    result = 0; // just to be explicit
    for (uint256 i = 0; i < list.length; i++) {
      result = result.add(list[i]);
    }
  }
}
