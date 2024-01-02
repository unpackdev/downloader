// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

abstract contract BaseChecker {
  error ZeroParameter();
  error InconsistentLengths();

  function _checkZeroValue(uint256 val) internal pure {
    if (val == 0) revert ZeroParameter();
  }

  function _checkZeroAddress(address addr) internal pure {
    if (addr == address(0x0)) revert ZeroParameter();
  }

  function _checkForConsistentLength(address[] memory arr1, uint256[] memory arr2) internal pure {
    if (arr1.length != arr2.length) revert InconsistentLengths();
  }
}
