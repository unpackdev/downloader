// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./TokenBase.sol";

contract PuulToken is TokenBase {
  constructor (address helper, address mintTo) public TokenBase('PUUL Token', 'PUUL', address(0), helper) {
    _mint(mintTo, 100000 ether);
  }
}
