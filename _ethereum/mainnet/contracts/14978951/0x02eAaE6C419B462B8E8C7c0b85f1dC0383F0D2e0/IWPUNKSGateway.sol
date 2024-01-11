// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

interface IWPUNKSGateway {
  function depositPUNKS(
    address lendingPool,
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function depositAndLockPUNKS(
    address lendingPool,
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 lockType,
    uint16 referralCode
  ) external;

  function withdrawPUNKS(
    address lendingPool,
    uint256[] calldata punkIndices,
    uint256[] calldata amounts,
    address to
  ) external;
}
