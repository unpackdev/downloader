// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev This Multicall contract was modified from the one built by OZ. It supports both payable and non payable
 * functions. However if `msg.value` is not zero, then non payable functions cannot be called.
 */
abstract contract Multicall {
  /**
   * @dev Receives and executes a batch of function calls on this contract.
   */
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
    return results;
  }
}
