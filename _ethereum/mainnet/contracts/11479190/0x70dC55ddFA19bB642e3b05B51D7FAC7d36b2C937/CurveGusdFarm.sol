// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./CurveFarm.sol";
import "./Console.sol";

contract CurveGusdFarm is CurveFarm {
  using Address for address;

  constructor (address pool, address[] memory rewards) public CurveFarm(pool, rewards) {
  }

}