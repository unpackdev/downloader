pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ISafeView.sol";
import "./Create2.sol";

library SafeViewLib {
  struct SafeViewResult {
    bool success;
    bytes data;
  }
  function executeLogic(address viewLayer, bytes memory context) internal returns (SafeViewResult memory) {
    (bool success, bytes memory retval) = viewLayer.delegatecall(encodeExecute(context));
    return SafeViewResult({
      success: success,
      data: retval
    });
  }
  function encodeResult(SafeViewResult memory input) internal pure returns (bytes memory retval) {
    retval = abi.encode(input);
  }
  function revertWithData(bytes memory input) internal pure {
    assembly {
      revert(add(input, 0x20), mload(input))
    }
  }
  function decodeViewResult(bytes memory data) internal pure returns (SafeViewResult memory result) {
     (result) = abi.decode(data, (SafeViewResult));
   }
   function encodeExecuteSafeView(bytes memory creationCode, bytes memory context) internal pure returns (bytes memory retval) {
     retval = abi.encodeWithSelector(ISafeView._executeSafeView.selector, creationCode, context);
   }
   function encodeExecute(bytes memory context) internal pure returns (bytes memory retval) {
     retval = abi.encodeWithSelector(ISafeView.execute.selector, context);
   }
  function safeView(bytes memory creationCode, bytes memory context) internal returns (SafeViewLib.SafeViewResult memory) {
    (/* bool success */, bytes memory retval) = address(this).call(encodeExecuteSafeView(creationCode, context));
    return decodeViewResult(retval);
  }
  bytes32 constant STEALTH_VIEW_DEPLOY_SALT = 0xad53495153c7c363e98a26920ec679e0e687636458f6908c91cf6deadb190801;
  function GET_STEALTH_VIEW_DEPLOY_SALT() internal pure returns (bytes32) {
    return STEALTH_VIEW_DEPLOY_SALT;
  }
  function deriveViewAddress(bytes memory creationCode) internal view returns (address) {
    return Create2.computeAddress(STEALTH_VIEW_DEPLOY_SALT, keccak256(creationCode));
  }
}
