// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./VoxFarm.sol";
import "./Console.sol";

contract VOX_USDCFarm is VoxFarm {
  using Address for address;

  uint256 constant POOL_ID = 2;
  address constant MASTER = 0x5B82b3DA49a6A7b5eea8F1b5d3c35766AF614cF0;
  address constant VOX_USDC = 0xe37D2Af2d33049935038826046bC03a62A3A1426;
  address constant VOX_TOKEN = 0x12D102F06da35cC0111EB58017fd2Cd28537d0e1;
  
  constructor (address pool, address[] memory rewards, address fees) public VoxFarm(pool, MASTER, VOX_USDC, rewards, POOL_ID, fees) {
  }

}
