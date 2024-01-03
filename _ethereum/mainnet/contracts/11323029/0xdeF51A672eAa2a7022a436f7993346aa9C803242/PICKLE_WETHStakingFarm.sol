// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./SushiSwapFarm.sol";
import "./Console.sol";

contract PICKLE_WETHStakingFarm is SushiSwapFarm {
  using Address for address;

  uint256 constant SUSHI_ID = 0;
  address constant MASTER_CHEF = 0xbD17B1ce622d73bD438b9E658acA5996dc394b0d;
  address constant PICKLE_WETH = 0xdc98556Ce24f007A5eF6dC1CE96322d65832A819;
  address constant PICKLE_TOKEN = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;
  
  constructor (address pool, address[] memory rewards, address fees) public SushiSwapFarm(pool, MASTER_CHEF, PICKLE_WETH, rewards, SUSHI_ID, fees) {
  }

}
