// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IKernel {
  /// @param account The address of the account to check if they are a manager
  /// @return Bool indicating whether the account is a manger
  function isManager(address account) external view returns (bool);

  /// @param account The address of the account to check if they are an owner
  /// @return Bool indicating whether the account is an owner
  function isOwner(address account) external view returns (bool);
}
