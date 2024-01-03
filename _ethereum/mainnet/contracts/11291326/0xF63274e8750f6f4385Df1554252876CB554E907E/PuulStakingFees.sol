// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Fees.sol";

contract PuulStakingFees is Fees {
  constructor (address helper, address withdrawal, uint256 withdrawalFee) public Fees(helper, withdrawal, withdrawalFee, address(0), 0) {
  }
}
