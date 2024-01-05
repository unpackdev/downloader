// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IKyberGovernance.sol";
import "./IVotingPowerStrategy.sol";
import "./IProposalValidator.sol";
import "./SafeMath.sol";
import "./Utils.sol";

/**
 * @title Proposal Validator Contract, inherited by Kyber Executors
 * @dev Validates/Invalidates propositions state modifications
 * Proposition Power functions: Validates proposition creations/ cancellation
 * Voting Power functions: Validates success of propositions.
 * @author Aave
 **/
contract DefaultProposalValidator is IProposalValidator, Utils {
  using SafeMath for uint256;

  uint256 public immutable override MIN_VOTING_DURATION;
  uint256 public immutable override MAX_VOTING_OPTIONS;
  uint256 public immutable override VOTE_DIFFERENTIAL;
  uint256 public immutable override MINIMUM_QUORUM;

  uint256 public constant YES_INDEX = 0;
  uint256 public constant NO_INDEX = 1;

  /**
   * @dev Constructor
   * @param minVotingDuration minimum duration in seconds of the voting period
   * @param maxVotingOptions maximum no. of vote options possible for a generic proposal
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In BPS
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In BPS
   **/
  constructor(
    uint256 minVotingDuration,
    uint256 maxVotingOptions,
    uint256 voteDifferential,
    uint256 minimumQuorum
  ) {
    MIN_VOTING_DURATION = minVotingDuration;
    MAX_VOTING_OPTIONS = maxVotingOptions;
    VOTE_DIFFERENTIAL = voteDifferential;
    MINIMUM_QUORUM = minimumQuorum;
  }

  /**
   * @dev Called to validate the cancellation of a proposal
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the generic proposal
   * @param user entity initiating the cancellation
   * @return boolean, true if can be cancelled
   **/
  function validateProposalCancellation(
    IKyberGovernance governance,
    uint256 proposalId,
    address user
  ) external override pure returns (bool) {
    // silence compilation warnings
    governance;
    proposalId;
    user;
    return false;
  }

  /**
   * @dev Called to validate a binary proposal
   * @notice creator of proposals must be the daoOperator
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateBinaryProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    address daoOperator
  ) external override view returns (bool) {
    // check authorization
    if (creator != daoOperator) return false;
    // check vote duration
    if (endTime.sub(startTime) < MIN_VOTING_DURATION) return false;

    return strategy.validateProposalCreation(startTime, endTime);
  }

  /**
   * @dev Called to validate a generic proposal
   * @notice creator of proposals must be the daoOperator
   * @param strategy votingPowerStrategy contract to calculate voting power
   * @param creator address of the creator
   * @param startTime timestamp when vote starts
   * @param endTime timestamp when vote ends
   * @param options list of proposal vote options
   * @param daoOperator address of daoOperator
   * @return boolean, true if can be created
   **/
  function validateGenericProposalCreation(
    IVotingPowerStrategy strategy,
    address creator,
    uint256 startTime,
    uint256 endTime,
    string[] calldata options,
    address daoOperator
  ) external override view returns (bool) {
    // check authorization
    if (creator != daoOperator) return false;
    // check vote duration
    if (endTime.sub(startTime) < MIN_VOTING_DURATION) return false;
    // check options length
    if (options.length <= 1 || options.length > MAX_VOTING_OPTIONS) return false;

    return strategy.validateProposalCreation(startTime, endTime);
  }

  /**
   * @dev Returns whether a binary proposal passed or not
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to set
   * @return true if proposal passed
   **/
  function isBinaryProposalPassed(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /**
   * @dev Check whether a binary proposal has reached quorum
   * Here quorum is not the number of votes reached, but number of YES_VOTES
   * @param governance governance contract to fetch proposals from
   * @param proposalId Id of the proposal to verify
   * @return true if minimum quorum is reached
   **/
  function isQuorumValid(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);
    if (proposal.proposalType != IKyberGovernance.ProposalType.Binary) return false;
    return isMinimumQuorumReached(proposal.voteCounts[YES_INDEX], proposal.maxVotingPower);
  }

  /**
   * @dev Check whether a binary proposal has sufficient YES_VOTES
   * YES_VOTES - NO_VOTES > VOTE_DIFFERENTIAL * voting supply
   * @param governance Governance Contract
   * @param proposalId Id of the proposal to verify
   * @return true if enough YES_VOTES
   **/
  function isVoteDifferentialValid(IKyberGovernance governance, uint256 proposalId)
    public
    override
    view
    returns (bool)
  {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);
    if (proposal.proposalType != IKyberGovernance.ProposalType.Binary) return false;
    return (
      proposal.voteCounts[YES_INDEX].mul(BPS).div(proposal.maxVotingPower) >
      proposal.voteCounts[NO_INDEX].mul(BPS).div(proposal.maxVotingPower).add(
      VOTE_DIFFERENTIAL
    ));
  }

  function isMinimumQuorumReached(uint256 votes, uint256 voteSupply) internal view returns (bool) {
    return votes >= voteSupply.mul(MINIMUM_QUORUM).div(BPS);
  }
}
