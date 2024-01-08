//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

library EthAddressLib {
  /**
   * @dev Returns the address used within the protocol to identify ETH
   * @return The address assigned to ETH
   */
  function ethAddress() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }
}
