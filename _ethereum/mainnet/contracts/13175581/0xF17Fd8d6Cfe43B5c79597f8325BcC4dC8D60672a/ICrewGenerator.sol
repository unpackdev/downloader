// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface ICrewGenerator {

  function setSeed(bytes32 _seed) external;

  function getFeatures(uint _crewId, uint _mod) external view returns (uint);
}
