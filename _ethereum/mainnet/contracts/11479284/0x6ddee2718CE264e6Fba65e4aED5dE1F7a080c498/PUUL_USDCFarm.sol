// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./FarmEndpointV2.sol";

contract PUUL_USDCFarm is FarmEndpointV2 {
  constructor (address pool, address[] memory rewards) public FarmEndpointV2(pool, rewards) {
  }
}