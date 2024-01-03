// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./BarnbridgeFarm.sol";
import "./Console.sol";

contract USDC_BONDFarm is BarnbridgeFarm {
  using Address for address;

  address constant USDC_BOND = 0x6591c4BcD6D7A1eb4E537DA8B78676C1576Ba244;
  address constant BOND_TOKEN = 0x0391D2021f89DC339F60Fff84546EA23E337750f;
  address constant HARVEST_FARM = 0xC25c37c387C5C909a94055F4f16184ca325D3a76;
  
  constructor (address pool, address[] memory rewards, address fees) public BarnbridgeFarm(pool, HARVEST_FARM, USDC_BOND, rewards, fees) {
  }

}
