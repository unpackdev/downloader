// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./FarmEndpointV2.sol";

contract USDC_PUULFarm is FarmEndpointV2 {
  constructor (address pool, address[] memory rewards) public FarmEndpointV2(pool, rewards) {
  }
}