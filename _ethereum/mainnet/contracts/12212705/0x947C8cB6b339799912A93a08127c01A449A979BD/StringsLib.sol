// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./Strings.sol";

library StringsLib {
  function toString(uint256 v) internal pure returns (string memory result) {
    result = Strings.toString(v);
  } 
  function strConcat(string memory a, string memory b) internal pure returns (string memory result) {
    result = string(abi.encodePacked(a, b));
  }
}
