// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./BaseFarm.sol";
import "./Console.sol";
import "./IVox.sol";

contract VoxFarm is BaseFarm {
  using Address for address;

  uint256 _poolId;
  
  constructor (address pool, address farm, address staking, address[] memory rewards, uint256 poolId, address fees) public BaseFarm(pool, farm, staking, rewards, fees) {
    _poolId = poolId;
  }

  function _deposit(uint256 amount) internal override {
    IVox(address(_targetFarm)).deposit(_poolId, amount, true);
  }

  function _harvest() internal override {
    IVox(address(_targetFarm)).claim(_poolId);
  }

  function _withdraw(uint256 amount) internal override {
    IVox(address(_targetFarm)).withdraw(_poolId, amount, true);
  }

}