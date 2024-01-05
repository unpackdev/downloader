// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./DefaultExecutorWithTimelock.sol";
import "./DefaultProposalValidator.sol";

/**
 * @title Time Locked, Validator, Executor Contract
 * @dev Contract
 * - Validate Proposal creations/ cancellation
 * - Validate Vote Quorum and Vote success on proposal
 * - Queue, Execute, Cancel, successful proposals' transactions.
 **/
contract DefaultExecutor is DefaultExecutorWithTimelock, DefaultProposalValidator {
  constructor(
    address admin,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    uint256 minVoteDuration,
    uint256 maxVotingOptions,
    uint256 voteDifferential,
    uint256 minimumQuorum
  )
    DefaultExecutorWithTimelock(admin, delay, gracePeriod, minimumDelay, maximumDelay)
    DefaultProposalValidator(minVoteDuration, maxVotingOptions, voteDifferential, minimumQuorum)
  {}
}
