// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface ICurveGauge {
  function withdraw(uint256 value) external;
  function deposit(uint256 value) external;
}
