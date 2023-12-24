// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IGovernorCharlieEvents.sol";
import "./IAMPH.sol";

import "./GovernanceStructs.sol";

interface IGovernorCharlie is IGovernorCharlieEvents {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Thrown when called by non governor
  error GovernorCharlie_NotGovernorCharlie();

  /// @notice Thrown when charlie is not active
  error GovernorCharlie_NotActive();

  /// @notice Thrown when votes are below the threshold
  error GovernorCharlie_VotesBelowThreshold();

  /// @notice Thrown when actions where not provided
  error GovernorCharlie_NoActions();

  /// @notice Thrown when too many actions
  error GovernorCharlie_TooManyActions();

  /// @notice Thrown when trying to create more than one active proposal per proposal
  error GovernorCharlie_MultipleActiveProposals();

  /// @notice Thrown when there is more than one pending proposal per proposer
  error GovernorCharlie_MultiplePendingProposals();

  /// @notice Thrown when there is information arity mismatch
  error GovernorCharlie_ArityMismatch();

  /// @notice Thrown when trying to queue a proposal that is not in the Succeeded state
  error GovernorCharlie_ProposalNotSucceeded();

  /// @notice Thrown when trying to queue an already queued proposal
  error GovernorCharlie_ProposalAlreadyQueued();

  /// @notice Thrown when delay has not been reached yet
  error GovernorCharlie_DelayNotReached();

  /// @notice Thrown when trying to execute a proposal that was not queued
  error GovernorCharlie_ProposalNotQueued();

  /// @notice Thrown when trying to execute a proposal that hasn't reached its timelock
  error GovernorCharlie_TimelockNotReached();

  /// @notice Thrown when trying to execute a transaction that is stale
  error GovernorCharlie_TransactionStale();

  /// @notice Thrown when transaction execution reverted
  error GovernorCharlie_TransactionReverted();

  /// @notice Thrown when trying to cancel a proposal that was already execute
  error GovernorCharlie_ProposalAlreadyExecuted();

  /// @notice Thrown when trying to cancel a whitelisted proposer's proposal
  error GovernorCharlie_WhitelistedProposer();

  /// @notice Thrown when proposal is above threshold
  error GovernorCharlie_ProposalAboveThreshold();

  /// @notice Thrown when received an invalid proposal id
  error GovernorCharlie_InvalidProposalId();

  /// @notice Thrown when trying to cast a vote with an invalid signature
  error GovernorCharlie_InvalidSignature();

  /// @notice Thrown when voting is closed
  error GovernorCharlie_VotingClosed();

  /// @notice Thrown when invalid vote type
  error GovernorCharlie_InvalidVoteType();

  /// @notice Thrown when voter already voted
  error GovernorCharlie_AlreadyVoted();

  /// @notice Thrown when expiration exceeds max
  error GovernorCharlie_ExpirationExceedsMax();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
    //////////////////////////////////////////////////////////////*/

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  function quorumVotes() external view returns (uint256 _quorumVotes);

  /// @notice The number of votes in support of a proposal required in order for an emergency quorum to be reached and for a vote to succeed
  function emergencyQuorumVotes() external view returns (uint256 _emergencyQuorumVotes);

  /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
  function votingDelay() external view returns (uint256 _votingDelay);

  /// @notice The duration of voting on a proposal, in blocks
  function votingPeriod() external view returns (uint256 _votingPeriod);

  /// @notice The number of votes required in order for a voter to become a proposer
  function proposalThreshold() external view returns (uint256 _proposalThreshold);

  /// @notice Initial proposal id set at become
  function initialProposalId() external view returns (uint256 _initialProposalId);

  /// @notice The total number of proposals
  function proposalCount() external view returns (uint256 _proposalCount);

  /// @notice The address of the Amphora Protocol governance token
  function amph() external view returns (IAMPH _amph);

  /// @notice The latest proposal for each proposer
  function latestProposalIds(address _proposer) external returns (uint256 _proposerId);

  /// @notice The mapping that saves queued transactions
  function queuedTransactions(bytes32 _transaction) external returns (bool _isQueued);

  /// @notice The proposal holding period
  function proposalTimelockDelay() external view returns (uint256 _proposalTimelockDelay);

  /// @notice Stores the expiration of account whitelist status as a timestamp
  function whitelistAccountExpirations(address _account) external returns (uint256 _expiration);

  /// @notice Address which manages whitelisted proposals and whitelist accounts
  function whitelistGuardian() external view returns (address _guardian);

  /// @notice The duration of the voting on a emergency proposal, in blocks
  function emergencyVotingPeriod() external view returns (uint256 _emergencyVotingPeriod);

  /// @notice The emergency proposal holding period
  function emergencyTimelockDelay() external view returns (uint256 _emergencyTimelockDelay);

  /// @notice The number of votes to reject an optimistic proposal
  function optimisticQuorumVotes() external view returns (uint256 _optimisticQuorumVotes);

  function optimisticVotingDelay() external view returns (uint256 _optimisticVotingDelay);

  /// @notice The delay period before voting begins
  function maxWhitelistPeriod() external view returns (uint256 _maxWhitelistPeriod);

  /// @notice Returns the timelock address
  /// @param _timelock The timelock address
  function timelock() external view returns (address _timelock);

  /// @notice Returns the proposal time lock delay
  /// @return _delay The proposal time lock delay
  function delay() external view returns (uint256 _delay);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
    //////////////////////////////////////////////////////////////*/

  // @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
  // @param _targets Target addresses for proposal calls
  // @param _values Eth values for proposal calls
  // @param _signatures Function signatures for proposal calls
  // @param _calldatas Calldatas for proposal calls
  // @param _description String description of the proposal
  // @return _proposalId Proposal id of new proposal
  function propose(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description
  ) external returns (uint256 _proposalId);

  // @notice Function used to propose a new emergency proposal. Sender must have delegates above the proposal threshold
  // @param _targets Target addresses for proposal calls
  // @param _values Eth values for proposal calls
  // @param _signatures Function signatures for proposal calls
  // @param _calldatas Calldatas for proposal calls
  // @param _description String description of the proposal
  // @return _proposalId Proposal id of new proposal
  function proposeEmergency(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description
  ) external returns (uint256 _proposalId);

  // @notice Queues a proposal of state succeeded
  // @param _proposalId The id of the proposal to queue
  function queue(uint256 _proposalId) external;

  // @notice Executes a queued proposal if eta has passed
  // @param _proposalId The id of the proposal to execute
  function execute(uint256 _proposalId) external payable;

  /// @notice Executes a transaction
  /// @param _target Target address for transaction
  /// @param _value Eth value for transaction
  /// @param _signature Function signature for transaction
  /// @param _data Calldata for transaction
  /// @param _eta Timestamp for transaction
  function executeTransaction(
    address _target,
    uint256 _value,
    string memory _signature,
    bytes memory _data,
    uint256 _eta
  ) external payable;

  // @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
  // @notice whitelistGuardian can cancel proposals from whitelisted addresses
  // @param _proposalId The id of the proposal to cancel
  function cancel(uint256 _proposalId) external;

  // @notice Gets actions of a proposal
  // @param _proposalId The id of the proposal
  // @return _targets The proposal targets
  // @return _values The proposal values
  // @return _signatures The proposal signatures
  // @return _calldatas The proposal calldata
  function getActions(uint256 _proposalId)
    external
    view
    returns (
      address[] memory _targets,
      uint256[] memory _values,
      string[] memory _signatures,
      bytes[] memory _calldatas
    );

  // @notice Returns the proposal
  // @param _proposalId The id of proposal
  // @return _proposal The proposal
  function getProposal(uint256 _proposalId) external view returns (Proposal memory _proposal);

  // @notice Gets the receipt for a voter on a given proposal
  // @param _proposalId The id of proposal
  // @param _voter The address of the voter
  // @return _receipt The voting receipt
  function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory _receipt);

  // @notice Gets the state of a proposal
  // @param _proposalId The id of the proposal
  // @return _proposalState Proposal state
  function state(uint256 _proposalId) external view returns (ProposalState _proposalState);

  // @notice Cast a vote for a proposal
  // @param _proposalId The id of the proposal to vote on
  // @param _support The support value for the vote. 0=against, 1=for, 2=abstain
  function castVote(uint256 _proposalId, uint8 _support) external;

  // @notice Cast a vote for a proposal with a reason
  // @param _proposalId The id of the proposal to vote on
  // @param _support The support value for the vote. 0=against, 1=for, 2=abstain
  // @param _reason The reason given for the vote by the voter
  function castVoteWithReason(uint256 _proposalId, uint8 _support, string calldata _reason) external;

  // @notice Cast a vote for a proposal by signature
  // @dev External override function that accepts EIP-712 signatures for voting on proposals.
  function castVoteBySig(uint256 _proposalId, uint8 _support, uint8 _v, bytes32 _r, bytes32 _s) external;

  // @notice View function which returns if an account is whitelisted
  // @param _account Account to check white list status of
  // @return _isWhitelisted If the account is whitelisted
  function isWhitelisted(address _account) external view returns (bool _isWhitelisted);

  // @notice Used to update the timelock period
  // @param _proposalTimelockDelay The proposal holding period
  function setDelay(uint256 _proposalTimelockDelay) external;

  // @notice Used to update the emergency timelock period
  // @param _emergencyTimelockDelay The proposal holding period
  function setEmergencyDelay(uint256 _emergencyTimelockDelay) external;

  // @notice Governance function for setting the voting delay
  // @param _newVotingDelay The new voting delay, in blocks
  function setVotingDelay(uint256 _newVotingDelay) external;

  // @notice Governance function for setting the voting period
  // @param _newVotingPeriod The new voting period, in blocks
  function setVotingPeriod(uint256 _newVotingPeriod) external;

  // @notice Governance function for setting the emergency voting period
  // @param _newEmergencyVotingPeriod The new voting period, in blocks
  function setEmergencyVotingPeriod(uint256 _newEmergencyVotingPeriod) external;

  // @notice Governance function for setting the proposal threshold
  // @param _newProposalThreshold The new proposal threshold
  function setProposalThreshold(uint256 _newProposalThreshold) external;

  // @notice Governance function for setting the quorum
  // @param _newQuorumVotes The new proposal quorum
  function setQuorumVotes(uint256 _newQuorumVotes) external;

  // @notice Governance function for setting the emergency quorum
  // @param _newEmergencyQuorumVotes The new proposal quorum
  function setEmergencyQuorumVotes(uint256 _newEmergencyQuorumVotes) external;

  // @notice Governance function for setting the whitelist expiration as a timestamp
  // for an account. Whitelist status allows accounts to propose without meeting threshold
  // @param _account Account address to set whitelist expiration for
  // @param _expiration Expiration for account whitelist status as timestamp (if now < expiration, whitelisted)
  function setWhitelistAccountExpiration(address _account, uint256 _expiration) external;

  // @notice Governance function for setting the whitelistGuardian. WhitelistGuardian can cancel proposals from whitelisted addresses
  // @param _account Account to set whitelistGuardian to (0x0 to remove whitelistGuardian)
  function setWhitelistGuardian(address _account) external;

  // @notice Governance function for setting the optimistic voting delay
  // @param _newOptimisticVotingDelay The new optimistic voting delay, in blocks
  function setOptimisticDelay(uint256 _newOptimisticVotingDelay) external;

  // @notice Governance function for setting the optimistic quorum
  // @param _newOptimisticQuorumVotes The new optimistic quorum votes, in blocks
  function setOptimisticQuorumVotes(uint256 _newOptimisticQuorumVotes) external;
}
