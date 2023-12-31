// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import "./GPv2Order.sol";

interface IConditionalOrder {
  /// Event that should be emitted in constructor so that the service "watching" for conditional orders can start indexing it
  event ConditionalOrderCreated(address indexed);

  /// Returns an order that if posted to the CoW Protocol API would pass signature validation
  /// Reverts in case current order condition is not met
  function getTradeableOrder() external view returns (GPv2Order.Data memory);
}
