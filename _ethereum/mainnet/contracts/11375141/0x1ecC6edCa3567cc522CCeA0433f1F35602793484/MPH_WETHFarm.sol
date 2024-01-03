// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./MphFarm.sol";
import "./Console.sol";

contract MPH_WETHFarm is MphFarm {
  using Address for address;

  address constant MPH_FARM = 0xd48Df82a6371A9e0083FbfC0DF3AF641b8E21E44;
  address constant MPH_WETH = 0x4D96369002fc5b9687ee924d458A7E5bAa5df34E;
 
  constructor (address pool, address[] memory rewards, address fees) public MphFarm(pool, MPH_FARM, MPH_WETH, rewards, fees) {
  }

}
