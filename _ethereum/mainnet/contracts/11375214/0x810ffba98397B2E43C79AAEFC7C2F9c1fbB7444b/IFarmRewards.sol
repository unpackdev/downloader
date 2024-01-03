// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IFarmRewards {
  function rewards() external view returns (address[] memory);
}
