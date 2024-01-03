pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SandboxLib.sol";
import "./ShifterBorrowProxyLib.sol";

interface IInitializationActionsReceiver {
  function receiveInitializationActions(ShifterBorrowProxyLib.InitializationAction[] calldata actions) external returns (SandboxLib.Context memory context);
}
