// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IExchanger {
  function exchangeOnBehalfWithTracking(
    address exchangeForAddress,
    bytes32 sourceCurrencyKey,
    uint256 sourceAmount,
    bytes32 destinationCurrencyKey,
    address originator,
    bytes32 trackingCode
  ) external returns (uint256 amountReceived);

  function exchangeOnBehalf(
    address exchangeForAddress,
    bytes32 sourceCurrencyKey,
    uint256 sourceAmount,
    bytes32 destinationCurrencyKey
  ) external returns (uint256 amountReceived);
}
