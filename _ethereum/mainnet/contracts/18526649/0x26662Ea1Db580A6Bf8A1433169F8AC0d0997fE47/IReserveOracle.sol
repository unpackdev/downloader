// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserveOracle {
  function activeMultiplier() external view returns (uint);
  function getCurrentPrice() external view returns (uint);
  function getCurrentMarketCap() external view returns (uint);
  function getCirculatingSupply() external view returns (uint);
  function getPercentageFromAth() external view returns (uint percentage);
  function setCurrentMultiplier() external returns (uint);
}