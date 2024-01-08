// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import "./PriorityTimelockExecutorMixin.sol";
import "./ProposalValidatorMixin.sol";

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations / cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author dYdX
 **/
contract PriorityExecutor is PriorityTimelockExecutorMixin, ProposalValidatorMixin {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 priorityPeriod,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum,
    address priorityExecutor
  )
    PriorityTimelockExecutorMixin(
      admin,
      delay,
      gracePeriod,
      minimumDelay,
      maximumDelay,
      priorityPeriod,
      priorityExecutor
    )
    ProposalValidatorMixin(
      propositionThreshold,
      voteDuration,
      voteDifferential,
      minimumQuorum
    )
  {}
}
