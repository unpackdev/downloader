// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ICrewFeatures {

  function setGeneratorSeed(uint _collId, bytes32 _seed) external;

  function setToken(uint _crewId, uint _collId, uint _mod) external;

  function getFeatures(uint _crewId) external view returns (uint);
}
