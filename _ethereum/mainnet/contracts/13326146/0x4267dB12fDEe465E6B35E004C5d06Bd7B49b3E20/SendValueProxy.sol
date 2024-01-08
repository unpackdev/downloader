// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ISendValueProxy.sol";

/**
 * @dev Contract that attempts to send value to an address.
 */
contract SendValueProxy is ISendValueProxy {
  /**
   * @dev Send some wei to the address.
   * @param _to address to send some value to.
   */
  function sendValue(address payable _to) external payable override {
    // Note that `<address>.transfer` limits gas sent to receiver. It may
    // not support complex contract operations in the future.
    _to.transfer(msg.value);
  }
}
