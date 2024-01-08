// SPDX-License-Identifier: AGPL-3.0
//
// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts

pragma solidity 0.7.5;
pragma abicoder v2;

import "./ExecutorWithTimelockMixin.sol";
import "./ProposalValidatorMixin.sol";

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 * @author dYdX
 **/
contract Executor is ExecutorWithTimelockMixin, ProposalValidatorMixin {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 propositionThreshold,
    uint256 voteDuration,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )
    ExecutorWithTimelockMixin(admin, delay, gracePeriod, minimumDelay, maximumDelay)
    ProposalValidatorMixin(propositionThreshold, voteDuration, voteDifferential, minimumQuorum)
  {}
}
