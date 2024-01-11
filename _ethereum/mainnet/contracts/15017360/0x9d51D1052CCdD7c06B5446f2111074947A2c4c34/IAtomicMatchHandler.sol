// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAtomicMatchHandler {
  function onAtomicMatch(
    address asset,
    uint256 assetId,
    uint256 assetAmount,
    address seller,
    address buyer,
    uint256 price
  ) external;
}
