pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";

library TokenUtils {
  function encodeTransfer(address target, uint256 amount) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSelector(IERC20.transfer.selector, target, amount);
  }
  function sendToken(address token, address target, uint256 amount) internal returns (bool) {
    (bool success,) = token.call(encodeTransfer(target, amount));
    return success;
  }
  function encodeTransferFrom(address from, address to, uint256 amount) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount);
  }
  function transferTokenFrom(address token, address from, address to, uint256 amount) internal returns (bool) {
    (bool success,) = token.call(encodeTransferFrom(from, to, amount));
    return success;
  }
  function encodeApproval(address target, uint256 amount) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSelector(IERC20.approve.selector, target, amount);
  }
  function approveToken(address token, address target, uint256 amount) internal returns (bool) {
    (bool success,) = token.call(encodeApproval(target, amount));
    return success;
  }
  uint256 constant THRESHOLD = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  uint256 constant MAX_UINT256 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  function approveForMaxIfNeeded(address token, address target) internal returns (bool) {
    uint256 approved = getApproved(token, address(this), target);
    if (approved > THRESHOLD) return true;
    if (approved != 0 && !approveToken(token, address(this), 0)) return false;
    return approveToken(token, target, MAX_UINT256);
  }
  function encodeAllowance(address source, address target) internal pure returns (bytes memory retval) {
    retval = abi.encodeWithSelector(IERC20.allowance.selector, source, target);
  }
  function decodeUint(bytes memory input) internal pure returns (uint256 retval) {
    (retval) = abi.decode(input, (uint256));
  }
  function getApproved(address token, address source, address target) internal returns (uint256) {
    (bool success, bytes memory retval) = token.call(encodeAllowance(source, target));
    if (!success || retval.length != 0x20) return 0x1;
    return decodeUint(retval);
  }
}
