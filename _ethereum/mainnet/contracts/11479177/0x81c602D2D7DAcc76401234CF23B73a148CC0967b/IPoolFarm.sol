// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPoolFarm {
  function claim() external;
  function updateAndClaim() external;
}
