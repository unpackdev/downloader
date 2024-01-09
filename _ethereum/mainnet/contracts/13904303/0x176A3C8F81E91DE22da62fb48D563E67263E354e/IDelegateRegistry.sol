// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;

interface IDelegateRegistry {
  function setDelegate(bytes32 id, address delegate) external;
}
