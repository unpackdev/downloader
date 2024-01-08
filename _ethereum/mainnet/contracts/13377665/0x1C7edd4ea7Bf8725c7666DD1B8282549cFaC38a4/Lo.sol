// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lo {
  function say() public virtual pure returns (string memory) {
    return 'Lo';
  }
}