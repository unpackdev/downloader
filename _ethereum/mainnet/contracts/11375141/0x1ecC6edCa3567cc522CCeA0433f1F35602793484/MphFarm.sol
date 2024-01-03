// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./BaseFarm.sol";
import "./Console.sol";
import "./IMph.sol";

contract MphFarm is BaseFarm {
  using Address for address;

  address constant MPH_TOKEN = 0x8888801aF4d980682e47f1A9036e589479e835C5;

  constructor (address pool, address farm, address staking, address[] memory rewards, address fees) public BaseFarm(pool, farm, staking, rewards, fees) {
  }

  function _deposit(uint256 amount) internal override {
    if (amount > 0)
      IMph(address(_targetFarm)).stake(amount);
  }

  function _harvest() internal override {
    IMph(address(_targetFarm)).getReward();
  }

  function _withdraw(uint256 amount) internal override {
    IMph(address(_targetFarm)).withdraw(amount);
  }

}