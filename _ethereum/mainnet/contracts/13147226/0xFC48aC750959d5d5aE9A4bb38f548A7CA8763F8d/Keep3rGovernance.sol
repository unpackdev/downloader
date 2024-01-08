// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IKeep3rGovernance.sol";
import "./EnumerableSet.sol";

abstract contract Keep3rGovernance is IKeep3rGovernance {
  address public override governance;
  address public override pendingGovernance;

  constructor(address _governance) {
    governance = _governance;
  }

  function setGovernance(address _governance) external override onlyGovernance {
    pendingGovernance = _governance;
    emit GovernanceProposal(_governance);
  }

  function acceptGovernance() external override onlyPendingGovernance {
    governance = pendingGovernance;
    delete pendingGovernance;
    emit GovernanceSet(governance);
  }

  modifier onlyGovernance {
    if (msg.sender != governance) revert OnlyGovernance();
    _;
  }

  modifier onlyPendingGovernance {
    if (msg.sender != pendingGovernance) revert OnlyPendingGovernance();
    _;
  }
}
