// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Address.sol";
import "./BaseFarm.sol";
import "./Console.sol";
import "./IBarnbridge.sol";
import "./IBarnbridgeHarvest.sol";

contract BarnbridgeFarm is BaseFarm {
  using Address for address;

  address _harvestFarm;
  address constant STAKING_FARM = 0xb0Fa2BeEe3Cf36a7Ac7E99B885b48538Ab364853;

  constructor (address pool, address harvestFarm, address stakingToken, address[] memory rewards, address fees) public BaseFarm(pool, STAKING_FARM, stakingToken, rewards, fees) {
    _harvestFarm = harvestFarm;
  }

  function _deposit(uint256 amount) internal override {
    if (amount > 0)
      IBarnbridge(address(_targetFarm)).deposit(address(_staking), amount);
  }

  function _harvest() internal override {
    IBarnbridgeHarvest(_harvestFarm).massHarvest();
  }

  function _withdraw(uint256 amount) internal override {
    IBarnbridge(address(_targetFarm)).withdraw(address(_staking), amount);
  }

}