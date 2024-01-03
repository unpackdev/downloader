// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IPoolFarmExtended {
  function claimToToken(address token, uint256[] memory amounts, uint256[] memory mins) external;
}
