// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./FarmEndpoint.sol";

contract PuulWithdrawalFeesEndpoint is FarmEndpoint {
  constructor (address pool, address[] memory rewards) public FarmEndpoint(pool, rewards) {
  }

}