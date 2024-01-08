// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor() {
    governor = msg.sender;
  }

  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    if (_pendingGovernor == address(0)) revert NoGovernorZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function acceptPendingGovernor() external override {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    emit PendingGovernorAccepted(governor, pendingGovernor);
    governor = pendingGovernor;
    pendingGovernor = address(0);
  }

  modifier onlyGovernor {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }
}
