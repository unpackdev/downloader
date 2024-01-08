// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface IUniMexFactory {
  function getPool(address) external returns(address);
  function getMaxLeverage(address) external returns(uint256);
  function allowedMargins(address) external returns (bool);
  function utilizationScaled(address token) external pure returns(uint256);
}