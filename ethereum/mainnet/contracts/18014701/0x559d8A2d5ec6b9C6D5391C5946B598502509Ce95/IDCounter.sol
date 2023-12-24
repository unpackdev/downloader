// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IIDCounter.sol";

abstract contract IDCounter is IIDCounter {
  uint256 internal _count;

  function count() external view override returns (uint256) {
    return _count;
  }

  function _next() internal virtual returns (uint256) {
    return _count++;
  }
}
