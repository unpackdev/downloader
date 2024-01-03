// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./BaseFarm.sol";
import "./Console.sol";
import "./IMasterChef.sol";

contract SushiSwapFarm is BaseFarm {
  using Address for address;

  uint256 _sushiId;
  
  constructor (address pool, address farm, address staking, address[] memory rewards, uint256 sushiId, address fees) public BaseFarm(pool, farm, staking, rewards, fees) {
    _sushiId = sushiId;
  }

  function _deposit(uint256 amount) internal override {
    IMasterChef(address(_targetFarm)).deposit(_sushiId, amount);
  }

  function _harvest() internal override {
    IMasterChef(address(_targetFarm)).deposit(_sushiId, 0);
  }

  function _withdraw(uint256 amount) internal override {
    IMasterChef(address(_targetFarm)).withdraw(_sushiId, amount);
  }

}