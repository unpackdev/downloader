// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IERC20.sol";
import "./Proxy.sol";

contract CoreFallThrough is Proxy {
  address internal constant DEFI5 = 0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41;
  address internal constant CC10 = 0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3;

  function _implementation() internal view virtual override returns (address) {
    return 0x669693A42B58E87b9e568bA2C6AdD607eb298d95;
  }

  function _beforeFallback() internal virtual override {
    if ((address(this) == DEFI5 || address(this) == CC10) && msg.sig != IERC20.balanceOf.selector) {
      revert("Contract disabled");
    }
  }
}