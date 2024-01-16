// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IGovernanceStrategy.sol";
import "./IAaveGovernanceV2.sol";
import "./IExecutor.sol";


/**
 * @title Executor
 * @author BGD Labs
 * @notice Time Locked, Validator, Executor Contract that:
 * - Validates Proposal creations/ cancellation
 * - Validates Vote Quorum and Vote success on proposal
 * - Allows queueing, execution and cancellation of proposals' transactions.
 **/
contract Executor is IExecutor {
  address private _admin;
  address private _pendingAdmin;
  uint256 private _delay;

  // uppercase is kept even not being constant/immutables, 
  // in order to keep interface compatibility with a previous version of the Executor
  uint256 public PROPOSITION_THRESHOLD;
  uint256 public VOTING_DURATION;
  uint256 public VOTE_DIFFERENTIAL;
  uint256 public MINIMUM_QUORUM;

  mapping(bytes32 => bool) private _queuedTransactions;  

  uint256 public immutable GRACE_PERIOD;
  uint256 public immutable MINIMUM_DELAY;
  uint256 public immutable MAXIMUM_DELAY;
  uint256 public constant ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision

  /**
   * @dev Constructor
   * @param admin admin address, that can call the main functions, (Governance)
   * @param delay minimum time between queueing and execution of proposal, in seconds
   * @param gracePeriod time after `delay` while a proposal can be executed, in seconds
   * @param minimumDelay lower threshold of `delay`, in seconds
   * @param maximumDelay upper threshold of `delay`, in seconds
   * @param propositionThreshold minimum percentage of supply needed to submit a proposal
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param voteDuration duration in blocks of the voting period
   * @param voteDifferential percentage of supply that `for` votes need to be over `against`
   *   in order for the proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
   * - In ONE_HUNDRED_WITH_PRECISION units
   **/
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
  {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _admin = admin;

    require(gracePeriod > 0, 'GRACE_PERIOD_LESS_THAN_0');
    GRACE_PERIOD = gracePeriod;

    MINIMUM_DELAY = minimumDelay;
    MAXIMUM_DELAY = maximumDelay;

    emit NewDelay(delay);
    emit NewAdmin(admin);

    _updateVotingDuration(voteDuration);
    _updateVoteDifferential(voteDifferential);
    _updateMinimumQuorum(minimumQuorum);
    _updatePropositionThreshold(propositionThreshold);
  }

  /**
  * -------------------------------------------------------------
  * --------------- IExecutorWithTimelock -----------------------
  * @dev logic for queue, execute, cancel transactions voted by Governance
  * Queued transactions can be executed after a delay and until
  * Grace period is not over.
  * -------------------------------------------------------------
  */

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'ONLY_BY_ADMIN');
    _;
  }

  modifier onlyPendingAdmin() {
    require(msg.sender == _pendingAdmin, 'ONLY_BY_PENDING_ADMIN');
    _;
  }

  modifier onlyExecutor {
    require(msg.sender == address(this), 'CALLER_NOT_EXECUTOR');
    _;
  }

  /// @inheritdoc IExecutor
  function setDelay(uint256 delay) external onlyExecutor {
    _validateDelay(delay);
    _delay = delay;

    emit NewDelay(delay);
  }

  /// @inheritdoc IExecutor
  function acceptAdmin() external onlyPendingAdmin {
    _admin = msg.sender;
    _pendingAdmin = address(0);

    emit NewAdmin(msg.sender);
  }

  /// @inheritdoc IExecutor
  function setPendingAdmin(address newPendingAdmin) external onlyExecutor {
    _pendingAdmin = newPendingAdmin;

    emit NewPendingAdmin(newPendingAdmin);
  }

  /// @inheritdoc IExecutor
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external onlyAdmin returns (bytes32) {
    require(executionTime >= block.timestamp + _delay, 'EXECUTION_TIME_UNDERESTIMATED');

    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = true;

    emit QueuedAction(actionHash, target, value, signature, data, executionTime, withDelegatecall);
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external onlyAdmin returns (bytes32) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    _queuedTransactions[actionHash] = false;

    emit CancelledAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall
    );
    return actionHash;
  }

  /// @inheritdoc IExecutor
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable onlyAdmin returns (bytes memory) {
    bytes32 actionHash = keccak256(
      abi.encode(target, value, signature, data, executionTime, withDelegatecall)
    );
    require(_queuedTransactions[actionHash], 'ACTION_NOT_QUEUED');
    require(block.timestamp >= executionTime, 'TIMELOCK_NOT_FINISHED');
    require(block.timestamp <= executionTime + GRACE_PERIOD, 'GRACE_PERIOD_FINISHED');

    _queuedTransactions[actionHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, 'NOT_ENOUGH_MSG_VALUE');
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, 'FAILED_ACTION_EXECUTION');

    emit ExecutedAction(
      actionHash,
      target,
      value,
      signature,
      data,
      executionTime,
      withDelegatecall,
      resultData
    );

    return resultData;
  }

  /// @inheritdoc IExecutor
  function getAdmin() external view returns (address) {
    return _admin;
  }

  /// @inheritdoc IExecutor
  function getPendingAdmin() external view returns (address) {
    return _pendingAdmin;
  }

  /// @inheritdoc IExecutor
  function getDelay() external view returns (uint256) {
    return _delay;
  }

  /// @inheritdoc IExecutor
  function isActionQueued(bytes32 actionHash) external view returns (bool) {
    return _queuedTransactions[actionHash];
  }

  /// @inheritdoc IExecutor
  function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);

    return (block.timestamp > proposal.executionTime + GRACE_PERIOD);
  }

  receive() external payable {}

  /**
  * --------------------------------------------------------
  * ---------- Proposal Validation -------------------------
  * @dev Validates/Invalidations propositions state modifications.
  * Proposition Power functions: Validates proposition creations/ cancellation
  * Voting Power functions: Validates success of propositions.
  * --------------------------------------------------------
  */

  /// @inheritdoc IExecutor
  function updateVotingDuration(uint256 votingDuration) external onlyExecutor {
    _updateVotingDuration(votingDuration);
  }
  
  /// @inheritdoc IExecutor
  function updateVoteDifferential(uint256 voteDifferential) external onlyExecutor {
    _updateVoteDifferential(voteDifferential);
  }

  /// @inheritdoc IExecutor
  function updateMinimumQuorum(uint256 minimumQuorum) external onlyExecutor {
    _updateMinimumQuorum(minimumQuorum);
  }

  /// @inheritdoc IExecutor
  function updatePropositionThreshold(uint256 propositionThreshold) external onlyExecutor {
    _updatePropositionThreshold(propositionThreshold);
  }

  /// @inheritdoc IExecutor
  function validateCreatorOfProposal(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool) {
    return isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function validateProposalCancellation(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) external view returns (bool) {
    return !isPropositionPowerEnough(governance, user, blockNumber);
  }

  /// @inheritdoc IExecutor
  function isPropositionPowerEnough(
    IAaveGovernanceV2 governance,
    address user,
    uint256 blockNumber
  ) public view returns (bool) {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy.getPropositionPowerAt(user, blockNumber) >=
      getMinimumPropositionPowerNeeded(governance, blockNumber);
  }

  /// @inheritdoc IExecutor
  function getMinimumPropositionPowerNeeded(IAaveGovernanceV2 governance, uint256 blockNumber)
    public
    view
    returns (uint256)
  {
    IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
      governance.getGovernanceStrategy()
    );
    return
      currentGovernanceStrategy
        .getTotalPropositionSupplyAt(blockNumber)
        * PROPOSITION_THRESHOLD
        / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isProposalPassed(IAaveGovernanceV2 governance, uint256 proposalId)
    external
    view
    returns (bool)
  {
    return (isQuorumValid(governance, proposalId) &&
      isVoteDifferentialValid(governance, proposalId));
  }

  /// @inheritdoc IExecutor
  function getMinimumVotingPowerNeeded(uint256 votingSupply)
    public
    view
    returns (uint256)
  {
    return votingSupply * MINIMUM_QUORUM / ONE_HUNDRED_WITH_PRECISION;
  }

  /// @inheritdoc IExecutor
  function isQuorumValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
  }

  /// @inheritdoc IExecutor
  function isVoteDifferentialValid(IAaveGovernanceV2 governance, uint256 proposalId)
    public
    view
    returns (bool)
  {
    IAaveGovernanceV2.ProposalWithoutVotes memory proposal = governance.getProposalById(proposalId);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );

    return (proposal.forVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) >
      ((proposal.againstVotes * ONE_HUNDRED_WITH_PRECISION / votingSupply) +
        VOTE_DIFFERENTIAL);
  }

  /// updates voting duration
  function _updateVotingDuration(uint256 votingDuration) internal {
    require(votingDuration > 0, 'VOTING_DURATION_CAN_NOT_BE_0');
    VOTING_DURATION = votingDuration;
    emit VotingDurationUpdated(votingDuration);
  }

  /// updates vote differential
  function _updateVoteDifferential(uint256 voteDifferential) internal {
    require(voteDifferential <= ONE_HUNDRED_WITH_PRECISION, 'VOTE_DIFFERENTIAL_CAN_NOT_BE_GREATER_THAN_100%');
    require(voteDifferential > 0, 'VOTE_DIFFERENTIAL_CAN_NOT_BE_LESS_THAN_0');
    VOTE_DIFFERENTIAL = voteDifferential;
    emit VoteDifferentialUpdated(voteDifferential);
  }

  /// updates minimum quorum
  function _updateMinimumQuorum(uint256 minimumQuorum) internal {
    require(minimumQuorum <= ONE_HUNDRED_WITH_PRECISION, 'MINIMUM_QUORUM_CAN_NOT_BE_GREATER_THAN_100%');
    require(minimumQuorum > 0, 'MINIMUM_QUORUM_CAN_NOT_BE_LESS_THAN_0');
    MINIMUM_QUORUM = minimumQuorum;
    emit MinimumQuorumUpdated(minimumQuorum);
  }

  /// updates proposition threshold
  function _updatePropositionThreshold(uint256 propositionThreshold) internal {
    require(propositionThreshold <= ONE_HUNDRED_WITH_PRECISION, 'PROPOSITION_THRESHOLD_CAN_NOT_BE_GREATER_THAN_100%');
    require(propositionThreshold > 0, 'PROPOSITION_THRESHOLD_CAN_NOT_BE_LESS_THAN_0');
    PROPOSITION_THRESHOLD = propositionThreshold;
    emit PropositionThresholdUpdated(propositionThreshold);
  }

  /// validates that a delay is correct
  function _validateDelay(uint256 delay) internal view {
    require(delay >= MINIMUM_DELAY, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= MAXIMUM_DELAY, 'DELAY_LONGER_THAN_MAXIMUM');
  }
}