// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;

contract MockCToken {
  address public underlying;

  constructor(address underlying_) public {
    underlying = underlying_;
  }
}
