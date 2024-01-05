// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IPlanets {
  
  function getElements(uint _planet) external pure returns (uint16[6] memory elements);

  function getType(uint _planet) external pure returns (uint8);

  function getRadius(uint _planet) external pure returns (uint32);

  function getPlanetWithTrojanAsteroids() external pure returns (uint16[6] memory);
}
