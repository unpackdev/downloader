// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.22;

/// @title StakeTogether Report Configuration
/// @notice This module includes configuration and reports related to the StakeTogether protocol.
/// @custom:security-contact security@staketogether.org
interface IRouter {
  /// @notice Emitted when a report for a specific block has already been executed.
  error AlreadyExecuted();

  /// @notice Emitted when an oracle has already reported for a specific block.
  error AlreadyReported();

  /// @notice Emitted when the beacon's balance is not enough to cover the loss amount.
  error BeaconBalanceTooLow();

  /// @notice Emitted when the block number has not yet reached the expected value for reporting.
  error BlockNumberNotReached();

  /// @notice Emitted when the report configuration is not yet set.
  error ConfigNotSet();

  /// @notice Emitted when the consensus is not yet delayed.
  error ConsensusNotDelayed();

  /// @notice Emitted when trying to execute too early.
  error EarlyExecution();

  /// @notice Emitted when the report's profit amount A is not enough for execution.
  error IncreaseOraclesToUseMargin();

  /// @notice Emitted when ETH balance is not enough for transaction.
  error InsufficientEthBalance();

  /// @notice Emitted when the oracles' margin is too high.
  error MarginTooHigh();

  /// @notice Emitted when there's no active consensus for a report block.
  error NoActiveConsensus();

  /// @notice Emitted when there is no pending execution for consensus.
  error NoPendingExecution();

  /// @notice Emitted when the report block is not yet reached.
  error OracleAlreadyReported();

  /// @notice Emitted when an oracle is not in the report oracles list.
  error OracleNotExists();

  /// @notice Emitted when an oracle is already in the report oracles list.
  error OracleExists();

  /// @notice Emitted when an oracle is already blacklisted.
  error OracleAlreadyBlacklisted();

  /// @notice Emitted when an oracle is blacklisted.
  error OracleBlacklisted();

  /// @notice Emitted when an oracle is not blacklisted.
  error OracleNotBlacklisted();

  /// @notice Emitted when an oracle is active.
  error OnlyActiveOracle();

  /// @notice Emitted when an action is attempted by an address other than the stakeTogether contract.
  error OnlyStakeTogether();

  /// @notice Emitted when there is a pending execution for consensus.
  error PendingExecution();

  /// @notice Emitted when the report delay blocks are too high.
  error ReportDelayBlocksTooHigh();

  /// @notice Emitted when a report for a specific block has already been revoked.
  error ReportRevoked();

  /// Emits when the report block is not greater than the last executed reportBlock.
  error ReportBlockShouldBeGreater();

  /// @notice Emitted when there are not enough oracles to use the margin.
  error RequiredMoreOracles();

  /// @notice Emitted when the quorum is not yet reached for consensus.
  error QuorumNotReached();

  /// @notice Emitted when a sentinel exists in the oracles list.
  error SentinelExists();

  /// @notice Emitted when a sentinel does not exist in the oracles list.
  error SentinelNotExists();

  /// @notice Emitted when trying to set the stakeTogether address that is already set.
  error StakeTogetherAlreadySet();

  /// @notice Emitted when the stakeTogether's withdraw balance is not enough.
  error WithdrawBalanceTooLow();

  /// @notice Thrown if the address trying to make a claim is the zero address.
  error ZeroAddress();

  /// @dev Config structure used for configuring the reporting mechanism in StakeTogether protocol.
  /// @param bunkerMode A boolean flag to indicate whether the bunker mode is active or not.
  /// @param reportFrequency The frequency in which reports need to be generated.
  /// @param reportDelayBlock The number of blocks to delay before a report is considered.
  /// @param oracleQuorum The quorum required among oracles for a report to be considered.
  struct Config {
    uint256 reportFrequency;
    uint256 reportDelayBlock;
    uint256 reportNoConsensusMargin;
    uint256 oracleQuorum;
  }

  /// @dev Report structure used for reporting the state of the protocol at different report blocks.
  /// @param reportBlock The specific block period for which this report is generated.
  /// @param merkleRoot The Merkle root hash representing the state of the data at this reportBlock.
  /// @param profitAmount The total profit amount generated during this reportBlock.
  /// @param profitShares The distribution of profits among stakeholders for this reportBlock.
  /// @param lossAmount The total loss amount incurred during this reportBlock.
  /// @param withdrawAmount The total amount withdrawn by users during this reportBlock.
  /// @param withdrawRefundAmount The amount refunded to users on withdrawal during this reportBlock.
  /// @param accumulatedReports The total number of reports accumulated up to this reportBlock.
  struct Report {
    uint256 reportBlock;
    bytes32 merkleRoot;
    uint256 profitAmount;
    uint256 profitShares;
    uint256 lossAmount;
    uint256 withdrawAmount;
    uint256 withdrawRefundAmount;
    uint256 accumulatedReports;
  }

  /// @notice Emitted when a new oracle is added for reporting.
  /// @param reportOracle The address of the oracle that was added.
  event AddReportOracle(address indexed reportOracle);

  /// @notice Emitted when an oracle is blacklisted.
  /// @param reportOracle The address of the oracle that was blacklisted.
  event BlacklistReportOracle(address indexed reportOracle);

  /// @notice Emitted when a report is approved by consensus.
  /// @param report The report details.
  event ConsensusApprove(uint256 indexed reportBlock, Report report);

  /// @notice Emitted when a report is approved by consensus.
  /// @param report The report details.
  event ConsensusFail(uint256 indexed reportBlock, Report report);

  /// @notice Emitted when a report is executed.
  /// @param sender The sneder oracle that execute the report.
  /// @param report The report details.
  event ExecuteReport(address indexed sender, uint256 indexed reportBlock, Report report);

  /// @notice Emitted when the contract receives ether.
  /// @param amount The amount of ether received.
  event ReceiveEther(uint256 indexed amount);

  /// @notice Emitted when Ether is received from Stake Together
  /// @param amount The amount of Ether received
  event ReceiveWithdrawEther(uint256 indexed amount);

  /// @notice Emitted when an oracle is removed from reporting.
  /// @param reportOracle The address of the oracle that was removed.
  event RemoveReportOracle(address indexed reportOracle);

  /// @notice Emitted when a consensus report is revoked.
  /// @param sender The sentinel that execute the revoke.
  /// @param reportBlock The block number at which the consensus was revoked.
  event RevokeConsensusReport(address indexed sender, uint256 indexed reportBlock);

  /// @notice Emitted when bunker mode is set.
  /// @param bunkerMode The bunker mode flag.
  event SetBunkerMode(bool indexed bunkerMode);

  /// @notice Emitted when the protocol configuration is updated.
  /// @param config The updated configuration.
  event SetConfig(Config indexed config);

  /// @notice Emitted when the StakeTogether address is set.
  /// @param stakeTogether The address of the StakeTogether contract.
  event SetStakeTogether(address indexed stakeTogether);

  /// @notice Emitted when the next report frequency is skipped.
  /// @param reportBlock The reportBlock for which the report frequency was skipped.
  /// @param reportNextBlock The block number at which the report frequency was skipped.
  event AdvanceNextBlock(uint256 indexed reportBlock, uint256 indexed reportNextBlock);

  /// @notice Emitted when a report is submitted.
  /// @param sender The address of the oracle that submitted the report.
  /// @param report The details of the submitted report.
  event SubmitReport(address indexed sender, Report indexed report);

  /// @notice Emitted when an oracle is unblacklisted.
  /// @param reportOracle The address of the oracle that was unblacklisted.
  event UnBlacklistReportOracle(address indexed reportOracle);

  /// @notice Initializes the contract after deployment.
  /// @dev Initializes various base contract functionalities and sets the initial state.
  /// @param _airdrop The address of the Airdrop contract.
  /// @param _withdrawals The address of the Withdrawals contract.
  function initialize(address _airdrop, address _withdrawals) external;

  /// @notice Pauses the contract functionalities.
  /// @dev Only the ADMIN_ROLE can pause the contract.
  function pause() external;

  /// @notice Resumes the contract functionalities after being paused.
  /// @dev Only the ADMIN_ROLE can unpause the contract.
  function unpause() external;

  /// @notice Receive ether to the contract.
  /// @dev An event is emitted with the amount of ether received.
  receive() external payable;

  /// @notice Allows the Stake Together to send ETH to the contract.
  /// @dev This function can only be called by the Stake Together.
  function receiveWithdrawEther() external payable;

  /// @notice Sets the address for the StakeTogether contract.
  /// @dev Only the ADMIN_ROLE can set the address, and the provided address must not be zero.
  /// @param _stakeTogether The address of the StakeTogether contract.
  function setStakeTogether(address _stakeTogether) external;

  /// @notice Sets the configuration parameters for the contract.
  /// @dev Only the ADMIN_ROLE can set the configuration, and it ensures a minimum report delay block.
  /// @param _config A struct containing various configuration parameters.
  function setConfig(Config memory _config) external;

  /// @notice Checks if an address is an active report oracle.
  /// @param _account Address of the oracle to be checked.
  function isReportOracle(address _account) external returns (bool);

  /// @notice Checks if a report oracle is blacklisted.
  /// @param _account Address of the oracle to be checked.
  function isReportOracleBlackListed(address _account) external view returns (bool);

  /// @notice Adds a new report oracle.
  /// @dev Only an account with the ORACLE_REPORT_MANAGER_ROLE can call this function.
  /// @param _account Address of the oracle to be added.
  function addReportOracle(address _account) external;

  /// @notice Removes an existing report oracle.
  /// @dev Only an account with the ORACLE_REPORT_MANAGER_ROLE can call this function.
  /// @param _account Address of the oracle to be removed.
  function removeReportOracle(address _account) external;

  /// @notice Blacklists a report oracle.
  /// @dev Only an account with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _account Address of the oracle to be blacklisted.
  function blacklistReportOracle(address _account) external;

  /// @notice Removes a report oracle from the blacklist.
  /// @dev Only an account with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _account Address of the oracle to be removed from the blacklist.
  function unBlacklistReportOracle(address _account) external;

  /// @notice Adds a new sentinel account.
  /// @dev Only an account with the ADMIN_ROLE can call this function.
  /// @param _account Address of the account to be added as sentinel.
  function addSentinel(address _account) external;

  /// @notice Removes an existing sentinel account.
  /// @dev Only an account with the ADMIN_ROLE can call this function.
  /// @param _account Address of the sentinel account to be removed.
  function removeSentinel(address _account) external;

  /// @notice Submit a report for the current reporting block.
  /// @dev Handles report submissions, checking for consensus or thresholds and preps next block if needed.
  /// It uses a combination of total votes for report to determine consensus.
  /// @param _report Data structure of the report.
  function submitReport(Report calldata _report) external;

  /// @notice Allows an active report oracle to execute an approved report.
  /// @dev Executes the actions based on the consensus-approved report.
  /// @param _report The data structure containing report details.
  function executeReport(Report calldata _report) external;

  /// @notice Forces to advance to nextReportBlock.
  function forceNextReportBlock() external;

  /// @notice Computes and returns the hash of a given report.
  /// @param _report The data structure containing report details.
  function getReportHash(Report calldata _report) external pure returns (bytes32);

  // @notice Revokes a consensus-approved report for a given reportBlock.
  /// @dev Only accounts with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _reportBlock The reportBlock for which the report was approved.
  function revokeConsensusReport(uint256 _reportBlock) external;

  /// @notice Validates if conditions to submit a report for an reportBlock are met.
  /// @dev Verifies conditions such as block number, consensus reportBlock, executed reports, and oracle votes.
  /// @param _report The data structure containing report details.
  function isReadyToSubmit(Report calldata _report) external view returns (bytes32);

  /// @notice Validates if conditions to execute a report are met.
  /// @dev Verifies conditions like revoked reports, executed reports, consensus reports, and beacon balance.
  /// @param _report The data structure containing report details.
  function isReadyToExecute(Report calldata _report) external view returns (bytes32);

  /// @notice Returns the next report block.
  function reportBlock() external view returns (uint256);
}
