pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SandboxLib.sol";
import "./ShifterBorrowProxyLib.sol";

library PreprocessorLib {
  function toContext(bytes memory input) internal pure returns (SandboxLib.ExecutionContext memory) {
    return SandboxLib.toContext(input);
  }
  function then(ShifterBorrowProxyLib.InitializationAction memory action, ShifterBorrowProxyLib.InitializationAction memory nextAction) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    result = new ShifterBorrowProxyLib.InitializationAction[](2);
    result[0] = action;
    result[1] = nextAction;
  }
  function getLastExecution(SandboxLib.Context memory context) internal pure returns (bool foundLast, SandboxLib.ProtectedExecution memory execution) {
    if (context.trace.length == 0) return (foundLast, execution);
    SandboxLib.ProtectedExecution[] memory lastBatch = context.trace[context.trace.length - 1];
    execution = lastBatch[lastBatch.length - 1];
  }
  function then(ShifterBorrowProxyLib.InitializationAction[] memory actions, ShifterBorrowProxyLib.InitializationAction[] memory nextActions) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    result = new ShifterBorrowProxyLib.InitializationAction[](actions.length + nextActions.length);
    uint256 i = 0;
    for (; i < actions.length; i++) {
      result[i] = actions[i];
    }
    for (uint256 j = 0; j < nextActions.length; j++) {
      result[i] = nextActions[j];
      i++;
    }
  }
  function then(ShifterBorrowProxyLib.InitializationAction[] memory actions, ShifterBorrowProxyLib.InitializationAction memory nextAction) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    result = then(actions, toList(nextAction));
  }
  function toList(ShifterBorrowProxyLib.InitializationAction memory input) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    result = new ShifterBorrowProxyLib.InitializationAction[](1);
    result[0] = input;
  }
  function sendTransaction(address to, bytes memory txData) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory result) {
    return toList(ShifterBorrowProxyLib.InitializationAction({
      to: to,
      txData: txData
    }));
  }
}
