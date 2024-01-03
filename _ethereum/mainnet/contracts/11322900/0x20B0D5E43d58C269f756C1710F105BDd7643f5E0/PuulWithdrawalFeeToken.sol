// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./TokenBase.sol";

contract PuulWithdrawalFeeToken is TokenBase {
  constructor (address helper) public TokenBase('PUUL Withdrawal Fee Token', 'PUULWTH', address(0), helper) {
    _mint(msg.sender, 100000 ether);
  }
}
