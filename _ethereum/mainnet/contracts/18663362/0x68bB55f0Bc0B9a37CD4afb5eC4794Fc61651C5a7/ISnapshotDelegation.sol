// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISnapshotDelegation {
  function delegation(address _user, bytes32 _id) external view returns (address);

  function clearDelegate(bytes32 _id) external;

  function setDelegate(bytes32 _id, address _delegate) external;
}
