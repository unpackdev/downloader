// SPDX-License-Identifier: MIT
// File contracts/interfaces/ITransferHook.sol
pragma solidity 0.7.5;

interface ITransferHook {
  function onTransfer(
    address from,
    address to,
    uint256 amount
  ) external;
}