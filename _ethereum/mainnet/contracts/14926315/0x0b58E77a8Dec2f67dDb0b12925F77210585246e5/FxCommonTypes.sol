// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract FxCommonTypes {
  bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
  bytes32 public constant WITHDRAW = keccak256("WITHDRAW");

  uint256 public constant BATCH_LIMIT = 15;
}
