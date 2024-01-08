// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;


interface IEthMap {
  function buyZone(uint zoneId) external payable returns (bool success);
  function sellZone(uint zoneId, uint amount) external returns (bool success);
  function transferZone(uint zoneId, address recipient) external returns (bool success);
  function computeInitialPrice(uint zoneId) external view returns (uint price);
  function getZone(uint zoneId) external view returns (uint id, address owner, uint sellPrice);
  function getBalance() external view returns (uint amount);
  function withdraw() external returns (bool success);
  function transferContractOwnership(address newOwner) external returns (bool success);
}