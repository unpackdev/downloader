// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISystemStatus {
  function synthExchangeSuspension(bytes32 input) external view returns (bool suspended, uint248 reason);
}
