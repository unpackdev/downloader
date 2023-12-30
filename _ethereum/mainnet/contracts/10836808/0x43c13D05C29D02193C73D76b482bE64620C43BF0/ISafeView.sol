pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ISafeView {
  function execute(bytes calldata) external;
  function _executeSafeView(bytes calldata, bytes calldata) external;
}
