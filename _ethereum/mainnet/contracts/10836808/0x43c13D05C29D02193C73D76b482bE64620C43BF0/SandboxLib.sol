pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SliceLib.sol";
import "./SafeViewLib.sol";
import "./BorrowProxy.sol";
import "./ShifterBorrowProxyLib.sol";
import "./RevertCaptureLib.sol";
import "./PreprocessorLib.sol";
import "./StringLib.sol";

library SandboxLib {
  using SafeViewLib for *;
  using SliceLib for *;
  using StringLib for *;
  using PreprocessorLib for *;
  struct ProtectedExecution {
    address to;
    bytes txData;
    bool success;
    bytes returnData;
  }
  function applyExecutionResult(ProtectedExecution[][] memory trace, uint256 index, ShifterBorrowProxyLib.InitializationAction[] memory preprocessed) internal pure returns (bool) {
    ProtectedExecution[] memory execution = new ProtectedExecution[](preprocessed.length);
    for (uint256 i = 0; i < execution.length; i++) {
      execution[i].txData = preprocessed[i].txData;
      execution[i].to = preprocessed[i].to;
    }
    trace[index] = execution;
    return execution.length != 0;
  }
  struct Context {
    address preprocessorAddress;
    ProtectedExecution[][] trace;
  }
  function encodeContext(ExecutionContext memory input) internal pure returns (bytes memory context) {
    context = abi.encode(input);
  }
  function toContext(bytes memory input) internal pure returns (ExecutionContext memory context) {
    (context) = abi.decode(input, (ExecutionContext));
  }
  function _write(ProtectedExecution[][] memory trace, uint256 newSize) internal pure {
    assembly {
      mstore(trace, newSize)
    }
  }
  function _restrict(Context memory context) internal pure {
    _write(context.trace, 0);
  }
  function _grow(Context memory context) internal pure {
    ProtectedExecution[][] memory trace = context.trace;
    uint256 newSize = trace.length;
    _write(trace, newSize + 1);
  }
  function toInitializationActions(bytes memory input) internal pure returns (ShifterBorrowProxyLib.InitializationAction[] memory action) {
    (action) = abi.decode(input, (ShifterBorrowProxyLib.InitializationAction[]));
  }
  function encodeInitializationActions(ShifterBorrowProxyLib.InitializationAction[] memory input) internal pure returns (bytes memory result) {
    result = abi.encode(input);
  }
  function _shrink(Context memory context) internal pure {
    _write(context.trace, context.trace.length - 1);
  }
  function encodeProxyCall(ProtectedExecution memory execution) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSelector(BorrowProxy.proxy.selector, execution.to, 0, execution.txData);
  }
  function toFlat(ProtectedExecution[][] memory execution) internal pure returns (ProtectedExecution[] memory trace) {
    uint256 total = 0;
    for (uint256 i = 0; i < execution.length; i++) {
      total += execution[i].length;
    }
    trace = new ProtectedExecution[](total);
    uint256 seen = 0;
    for (uint256 i = 0; i < execution.length; i++) {
      for (uint256 j = 0; j < execution[i].length; j++) {
        trace[seen] = execution[i][j];
      }
    }
  }
  function getNewContext(ShifterBorrowProxyLib.InitializationAction[] memory actions) internal pure returns (Context memory context) {
    ProtectedExecution[][] memory trace = new ProtectedExecution[][](actions.length);
    for (uint256 i = 0; i < actions.length; i++) {
      trace[i] = new ProtectedExecution[](1);
      trace[i][0].to = actions[i].to;
      trace[i][0].txData = actions[i].txData;
    }
    context = Context({
      trace: trace,
      preprocessorAddress: address(0)
    });
  }
  struct ExecutionContext {
    ProtectedExecution last;
    address preprocessorAddress;
  }
  function executeSafeView(bytes memory creationCode, uint256 index, Context memory context) internal returns (SafeViewLib.SafeViewResult memory result) {
    ExecutionContext memory executionContext;
    executionContext.preprocessorAddress = context.preprocessorAddress;
    if (index != 0) {
      ProtectedExecution[] memory lastBatch = context.trace[index];
      if (lastBatch.length != 0) executionContext.last = lastBatch[lastBatch.length - 1];
    }
    result = creationCode.safeView(encodeContext(executionContext));
  }
  function processActions(ShifterBorrowProxyLib.InitializationAction[] memory actions) internal returns (ProtectedExecution[] memory trace) {
    Context memory context = getNewContext(actions);
    for (uint256 i = 0; i < actions.length; i++) {
      ProtectedExecution[] memory execution = context.trace[i];
      if (execution[0].to == address(0x0)) {
        context.preprocessorAddress = execution[0].txData.deriveViewAddress();
        SafeViewLib.SafeViewResult memory safeViewResult = executeSafeView(execution[0].txData, i, context);
        execution[0].txData = new bytes(0x0);
        if (safeViewResult.success) {
          if (!applyExecutionResult(context.trace, i, toInitializationActions(safeViewResult.data))) break;
        } else {
          execution[0].returnData = safeViewResult.data;
          execution[0].success = safeViewResult.success;
// for debugging
          bytes memory data = execution[0].returnData;
          assembly {
            revert(add(data, 0x20), mload(data))
          }
// end
          continue;
        }
      }
      execution = context.trace[i];
      for (uint256 j = 0; j < execution.length; j++) {
        (bool success, bytes memory returnData) = address(this).call(encodeProxyCall(execution[j]));
        execution[j].success = success;
// for debugging
        if (!execution[j].success) {
          assembly {
            revert(add(0x20, returnData), mload(returnData))
          }
        }
// end
        execution[j].returnData = returnData;
      }
    }
    return toFlat(context.trace);
  }
}
