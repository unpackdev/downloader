// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./VoxFarm.sol";
import "./Console.sol";

contract VOX_WETHFarm is VoxFarm {
  using Address for address;

  uint256 constant POOL_ID = 1;
  address constant MASTER = 0x5B82b3DA49a6A7b5eea8F1b5d3c35766AF614cF0;
  address constant VOX_WETH = 0x3D3eE86a2127F4D20b1c533E2c1abd8040da1dd9;
  address constant VOX_TOKEN = 0x12D102F06da35cC0111EB58017fd2Cd28537d0e1;
  
  constructor (address pool, address[] memory rewards, address fees) public VoxFarm(pool, MASTER, VOX_WETH, rewards, POOL_ID, fees) {
  }

}
