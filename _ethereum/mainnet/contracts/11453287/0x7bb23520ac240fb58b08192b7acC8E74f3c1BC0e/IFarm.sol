// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IFarm {
  function earn() external;
  function harvest() external;
  function withdraw(uint256 amount) external;
}
