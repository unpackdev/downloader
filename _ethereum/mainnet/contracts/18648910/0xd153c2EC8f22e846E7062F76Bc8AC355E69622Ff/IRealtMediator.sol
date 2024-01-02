// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IRealtMediator {
  function batchBridgeFromVault(
   address[] calldata tokens,
        uint256[] calldata amounts,
        address destination
  ) external returns (bool);

  function batchTransferFromVault(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address destination
    ) external returns (bool);
}