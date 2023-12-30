pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeViewLib.sol";

contract ISafeViewExecutor {
  function query(bytes memory /* creationCode */, bytes memory /* context */) public view returns (SafeViewLib.SafeViewResult memory) {
   // stub
  }
}
