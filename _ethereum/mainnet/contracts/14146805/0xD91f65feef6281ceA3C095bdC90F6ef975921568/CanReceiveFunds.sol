// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CanReceiveFunds {
  receive() external payable {
  }
  fallback() external payable {
  }
}
