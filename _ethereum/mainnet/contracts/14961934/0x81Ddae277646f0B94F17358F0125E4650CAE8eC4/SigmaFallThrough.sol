// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IERC20.sol";
import "./Proxy.sol";

contract SigmaFallThrough is Proxy {
  address internal constant FFF = 0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413;
  address internal immutable drainReversalImplementation;

  constructor(address _drainReversalImplementation) {
    drainReversalImplementation = _drainReversalImplementation;
  }

  function _implementation() internal view virtual override returns (address) {
    if (address(this) == FFF) {
      return drainReversalImplementation;
    }
    return 0x7B3B2B39CbdBddaDC13D8559D82c054b9C2fd5f3;
  }
}
