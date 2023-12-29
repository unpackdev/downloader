// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGovernorCharlieEvents {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

  /// @notice An event emitted when a new proposal is created
  event ProposalCreatedIndexed(
    uint256 indexed _id,
    address indexed _proposer,
    address[] _targets,
    uint256[] _values,
    string[] _signatures,
    bytes[] _calldatas,
    uint256 indexed _startBlock,
    uint256 _endBlock,
    string _description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  /// @param _voter The address which casted a vote
  /// @param _proposalId The proposal id which was voted on
  /// @param _support Support value for the vote. 0=against, 1=for, 2=abstain
  /// @param _votes Number of votes which were cast by the voter
  /// @param _reason The reason given for the vote by the voter
  event VoteCastIndexed(
    address indexed _voter, uint256 indexed _proposalId, uint8 _support, uint256 _votes, string _reason
  );

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceledIndexed(uint256 indexed _id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueuedIndexed(uint256 indexed _id, uint256 _eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecutedIndexed(uint256 indexed _id);

  /// @notice An event emitted when the voting delay is set
  event VotingDelaySet(uint256 _oldVotingDelay, uint256 _newVotingDelay);

  /// @notice An event emitted when the voting period is set
  event VotingPeriodSet(uint256 _oldVotingPeriod, uint256 _newVotingPeriod);

  /// @notice An event emitted when the emergency voting period is set
  event EmergencyVotingPeriodSet(uint256 _oldEmergencyVotingPeriod, uint256 _emergencyVotingPeriod);

  /// @notice Emitted when proposal threshold is set
  event ProposalThresholdSet(uint256 _oldProposalThreshold, uint256 _newProposalThreshold);

  /// @notice Emitted when whitelist account expiration is set
  event WhitelistAccountExpirationSet(address _account, uint256 _expiration);

  /// @notice Emitted when the whitelistGuardian is set
  event WhitelistGuardianSet(address _oldGuardian, address _newGuardian);

  /// @notice Emitted when the a new delay is set
  event NewDelay(uint256 _oldTimelockDelay, uint256 _proposalTimelockDelay);

  /// @notice Emitted when the a new emergency delay is set
  event NewEmergencyDelay(uint256 _oldEmergencyTimelockDelay, uint256 _emergencyTimelockDelay);

  /// @notice Emitted when the quorum is updated
  event NewQuorum(uint256 _oldQuorumVotes, uint256 _quorumVotes);

  /// @notice Emitted when the emergency quorum is updated
  event NewEmergencyQuorum(uint256 _oldEmergencyQuorumVotes, uint256 _emergencyQuorumVotes);

  /// @notice An event emitted when the optimistic voting delay is set
  event OptimisticVotingDelaySet(uint256 _oldOptimisticVotingDelay, uint256 _optimisticVotingDelay);

  /// @notice Emitted when the optimistic quorum is updated
  event OptimisticQuorumVotesSet(uint256 _oldOptimisticQuorumVotes, uint256 _optimisticQuorumVotes);

  /// @notice Emitted when a transaction is canceled
  event CancelTransaction(
    bytes32 indexed _txHash, address indexed _target, uint256 _value, string _signature, bytes _data, uint256 _eta
  );

  /// @notice Emitted when a transaction is executed
  event ExecuteTransaction(
    bytes32 indexed _txHash, address indexed _target, uint256 _value, string _signature, bytes _data, uint256 _eta
  );

  /// @notice Emitted when a transaction is queued
  event QueueTransaction(
    bytes32 indexed _txHash, address indexed _target, uint256 _value, string _signature, bytes _data, uint256 _eta
  );

  /// @notice Emitted when a new governance token is set
  event NewTokenSet(address _oldToken, address _newToken);

  /// @notice Emitted when a max whitelist period is set
  event MaxWhitelistPeriodSet(uint256 _oldMaxWhitelistPeriod, uint256 _newMaxWhitelistPeriod);

  /*///////////////////////////////////////////////////////////////
                              TALLY EVENTS
  //////////////////////////////////////////////////////////////*/

  // This events are needed so that tally can index the votes and actions
  event ProposalCreated(
    uint256 _id,
    address _proposer,
    address[] _targets,
    uint256[] _values,
    string[] _signatures,
    bytes[] _calldatas,
    uint256 _startBlock,
    uint256 _endBlock,
    string _description
  );

  event VoteCast(address indexed _voter, uint256 _proposalId, uint8 _support, uint256 _votes, string _reason);
  event ProposalCanceled(uint256 _id);
  event ProposalQueued(uint256 _id, uint256 _eta);
  event ProposalExecuted(uint256 _id);
}
