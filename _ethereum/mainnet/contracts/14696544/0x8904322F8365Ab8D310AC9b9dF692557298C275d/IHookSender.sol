// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// ---------------------------------------------------------------------
// HookSender
// To make MultiSender can be a unlimited integration
// ---------------------------------------------------------------------
abstract contract IHookSender {
  function multiSenderLoop(
    address caller,
    uint index,
    uint maxLoop
  ) public virtual returns (bool success);
}
