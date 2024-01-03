// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IGovernor {
  function cancel(uint256 proposalId) external;

  function __acceptAdmin() external;

  function __abdicate() external;

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta)
    external;

  function __executeSetTimelockPendingAdmin(
    address newPendingAdmin,
    uint256 eta
  ) external;
}
