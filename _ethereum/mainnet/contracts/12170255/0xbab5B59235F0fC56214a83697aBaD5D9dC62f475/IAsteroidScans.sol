// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IAsteroidScans {

  function addManager(address _manager) external;

  function removeManager(address _manager) external;

  function isManager(address _manager) external view returns (bool);

  function recordScanOrder(uint _asteroidId) external;

  function getScanOrder(uint _asteroidId) external view returns(uint);

  function setInitialBonuses(uint[] calldata _asteroidIds, uint[] calldata _bonuses) external;

  function finalizeScan(uint _asteroidId) external;

  function retrieveScan(uint _asteroidId) external view returns (uint);
}
