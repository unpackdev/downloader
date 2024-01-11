// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IERC20.sol";
import "./Proxy.sol";

contract CoreFallThrough is Proxy {
  address internal constant DEFI5 = 0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41;
  address internal constant CC10 = 0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3;
  address internal immutable drainReversalImplementation;

  constructor(address _drainReversalImplementation) {
    drainReversalImplementation = _drainReversalImplementation;
  }

  function _implementation() internal view virtual override returns (address) {
    if (address(this) == DEFI5 || address(this) == CC10) {
      return drainReversalImplementation;
    }
    return 0x669693A42B58E87b9e568bA2C6AdD607eb298d95;
  }
}
