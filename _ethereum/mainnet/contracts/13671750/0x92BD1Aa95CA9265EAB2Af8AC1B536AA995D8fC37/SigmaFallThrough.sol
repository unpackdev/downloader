// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IERC20.sol";
import "./Proxy.sol";

contract SigmaFallThrough is Proxy {
  address internal constant FFF = 0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413;

  function _implementation() internal view virtual override returns (address) {
    return 0x7B3B2B39CbdBddaDC13D8559D82c054b9C2fd5f3;
  }

  function _beforeFallback() internal virtual override {
    if (address(this) == FFF && msg.sig != IERC20.balanceOf.selector) {
      revert("Contract disabled");
    }
  }
}