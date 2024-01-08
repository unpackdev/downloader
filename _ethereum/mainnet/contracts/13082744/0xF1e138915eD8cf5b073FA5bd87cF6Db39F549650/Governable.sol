//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

abstract contract Governable is IGovernable {
  address public override governor;
  address public override pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert NoGovernorZeroAddress();
    governor = _governor;
  }

  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    if (_pendingGovernor == address(0)) revert NoGovernorZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function acceptPendingGovernor() external override onlyPendingGovernor {
    emit PendingGovernorAccepted(governor, pendingGovernor);
    governor = pendingGovernor;
    pendingGovernor = address(0);
  }

  modifier onlyGovernor {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    _;
  }
}
