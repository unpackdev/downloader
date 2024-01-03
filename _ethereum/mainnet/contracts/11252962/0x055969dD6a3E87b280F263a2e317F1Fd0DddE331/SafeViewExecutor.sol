pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeViewLib.sol";
import "./Create2.sol";

contract SafeViewExecutor {
  using SafeViewLib for *;
  bytes32 constant STEALTH_VIEW_DEPLOY_SALT = 0xad53495153c7c363e98a26920ec679e0e687636458f6908c91cf6deadb190801;
  function _executeSafeView(bytes memory creationCode, bytes memory context) public {
    address viewLayer = Create2.deploy(0, SafeViewLib.GET_STEALTH_VIEW_DEPLOY_SALT(), creationCode);
    bytes memory result = viewLayer.executeLogic(context).encodeResult();
    result.revertWithData();
  }
  function query(bytes memory creationCode, bytes memory context) public returns (SafeViewLib.SafeViewResult memory) {
    return creationCode.safeView(context);
  }
}
