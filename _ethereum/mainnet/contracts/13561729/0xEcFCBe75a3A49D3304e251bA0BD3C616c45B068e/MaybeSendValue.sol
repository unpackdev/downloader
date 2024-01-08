// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./SendValueProxy.sol";

/**
 * @dev Contract with a ISendValueProxy that will catch reverts when attempting to transfer funds.
 */

contract MaybeSendValue {
  // SendValueProxy proxy;

  // constructor() {
  //     proxy = new SendValueProxy();
  // }

  /**
   * @dev Maybe send some wei to the address via a proxy. Returns true on success and false if transfer fails.
   * @param _to address to send some value to.
   * @param _value uint256 amount to send.
   */
  function maybeSendValue(address payable _to, uint256 _value) internal returns (bool) {
    _to.transfer(_value);

    return true;
  }
}
