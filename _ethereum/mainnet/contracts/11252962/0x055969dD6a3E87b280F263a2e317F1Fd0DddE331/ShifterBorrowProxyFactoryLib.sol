pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Create2.sol";
import "./ShifterBorrowProxy.sol";
import "./ShifterPoolLib.sol";
import "./FactoryLib.sol";

library ShifterBorrowProxyFactoryLib {
  function deployBorrowProxy(ShifterPoolLib.Isolate storage /* isolate */, bytes32 salt) external returns (address output) {
    output = Create2.deploy(0, salt, type(ShifterBorrowProxy).creationCode);
  }
  function deriveBorrowerAddress(address target, bytes32 salt) internal view returns (address) {
    return FactoryLib.deriveInstanceAddress(target, salt);
  }
}
