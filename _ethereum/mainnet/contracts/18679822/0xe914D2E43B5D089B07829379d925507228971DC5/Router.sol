// SPDX-FileCopyrightText: 2023 Stake Together Labs <legal@staketogether.org>
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Math.sol";
import "./Address.sol";

import "./IAirdrop.sol";
import "./IRouter.sol";
import "./IStakeTogether.sol";
import "./IWithdrawals.sol";

/// @title Router Contract for the StakeTogether platform.
/// @dev This contract handles routing functionalities, is pausable, upgradable, and guards against reentrancy attacks.
/// It also leverages access controls for administrative purposes. This contract should be initialized after deployment.
/// @custom:security-contact security@staketogether.org
contract Router is
  Initializable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable,
  IRouter
{
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE'); /// Role for managing upgrades.
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE'); /// Role for administration.
  bytes32 public constant ORACLE_REPORT_MANAGER_ROLE = keccak256('ORACLE_REPORT_MANAGER_ROLE'); /// Role for managing oracle reports.
  bytes32 public constant ORACLE_SENTINEL_ROLE = keccak256('ORACLE_SENTINEL_ROLE'); /// Role for sentinel functionality in oracle management.
  bytes32 public constant ORACLE_REPORT_ROLE = keccak256('ORACLE_REPORT_ROLE'); /// Role for reporting as an oracle.
  uint256 public version; /// Contract version.

  IAirdrop public airdrop; /// Instance of the Airdrop contract.
  IStakeTogether public stakeTogether; /// Instance of the StakeTogether contract.
  IWithdrawals public withdrawals; /// Instance of the Withdrawals contract.
  Config public config; /// Configuration settings for the protocol.
  bool public bunkermode; /// Configuration for beacon withdrawals speed.

  uint256 public totalReportOracles; /// Total number of reportOracles.
  mapping(address => bool) private reportOracles; /// Mapping to track oracle addresses.
  mapping(address => bool) public reportOraclesBlacklist; /// Mapping to track blacklisted reportOracles.

  mapping(uint256 => mapping(bytes32 => address[])) public reports; /// Mapping to track reports.
  mapping(uint256 => mapping(address => bool)) reportForBlock; /// Mapping to track blocks for reports.
  mapping(uint256 => uint256) public totalVotes; // Mapping to track block report votes for reports.
  mapping(uint256 => mapping(bytes32 => uint256)) public reportVotesForBlock; /// Mapping to track votes for reports.
  mapping(uint256 => bytes32) public consensusReport; /// Mapping to store consensus report by block report.
  mapping(uint256 => mapping(bytes32 => bool)) public executedReports; /// Mapping to check if a report has been executed.
  mapping(uint256 => bool) public revokedReports; /// Mapping to check if a report has been revoked.

  uint256 public reportBlock; /// The next block where a report is expected.
  uint256 public lastConsensusBlock; /// The last block where consensus was achieved.
  uint256 public lastExecutedBlock; /// The last block where a report was executed.
  bool public pendingExecution; /// Theres a report pending to be executed.

  mapping(uint256 => uint256) public reportDelayBlock; /// Mapping to track the delay for reports.

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the contract after deployment.
  /// @dev Initializes various base contract functionalities and sets the initial state.
  /// @param _airdrop The address of the Airdrop contract.
  /// @param _withdrawals The address of the Withdrawals contract.
  function initialize(address _airdrop, address _withdrawals) external initializer {
    __Pausable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    version = 1;

    airdrop = IAirdrop(payable(_airdrop));
    withdrawals = IWithdrawals(payable(_withdrawals));

    reportBlock = block.number;

    lastConsensusBlock = 1;
    lastExecutedBlock = 1;
  }

  /// @notice Pauses the contract functionalities.
  /// @dev Only the ADMIN_ROLE can pause the contract.
  function pause() external onlyRole(ADMIN_ROLE) {
    _pause();
  }

  /// @notice Resumes the contract functionalities after being paused.
  /// @dev Only the ADMIN_ROLE can unpause the contract.
  function unpause() external onlyRole(ADMIN_ROLE) {
    _unpause();
  }

  /// @notice Internal function to authorize an upgrade.
  /// @dev Overrides the base function and only the UPGRADER_ROLE can authorize the upgrade.
  /// @param _newImplementation Address of the new implementation for the upgrade.
  function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /// @notice Receive ether to the contract.
  /// @dev An event is emitted with the amount of ether received.
  receive() external payable {
    emit ReceiveEther(msg.value);
  }

  /// @notice Allows the Stake Together to send ETH to the contract.
  /// @dev This function can only be called by the Stake Together.
  function receiveWithdrawEther() external payable {
    if (msg.sender != address(stakeTogether)) revert OnlyStakeTogether();
    emit ReceiveWithdrawEther(msg.value);
  }

  /// @notice Sets the address for the StakeTogether contract.
  /// @dev Only the ADMIN_ROLE can set the address, and the provided address must not be zero.
  /// @param _stakeTogether The address of the StakeTogether contract.
  function setStakeTogether(address _stakeTogether) external onlyRole(ADMIN_ROLE) {
    if (address(stakeTogether) != address(0)) revert StakeTogetherAlreadySet();
    if (_stakeTogether == address(0)) revert ZeroAddress();
    stakeTogether = IStakeTogether(payable(_stakeTogether));
    emit SetStakeTogether(_stakeTogether);
  }

  /************
   ** CONFIG **
   ************/

  /// @notice Sets the bunkermode for beacon withdrawals.
  /// @param _bunkerMode A boolean indicating if the bunkermode is active.
  function setBunkerMode(bool _bunkerMode) external onlyRole(ADMIN_ROLE) {
    bunkermode = _bunkerMode;
    emit SetBunkerMode(_bunkerMode);
  }

  /// @notice Sets the configuration parameters for the contract.
  /// @dev Only the ADMIN_ROLE can set the configuration, and it ensures a minimum report delay block.
  /// @param _config A struct containing various configuration parameters.
  function setConfig(Config memory _config) external onlyRole(ADMIN_ROLE) {
    config = _config;
    if (config.reportDelayBlock >= config.reportFrequency) revert ReportDelayBlocksTooHigh();
    if (config.reportNoConsensusMargin >= config.oracleQuorum) revert MarginTooHigh();
    emit SetConfig(_config);
  }

  /*******************
   ** REPORT ORACLE **
   *******************/

  /// @dev Modifier to ensure that the caller is an active report oracle.
  modifier activeReportOracle() {
    if (!isReportOracle(msg.sender)) revert OnlyActiveOracle();
    _;
  }

  /// @notice Checks if an address is an active report oracle.
  /// @param _account Address of the oracle to be checked.
  /// @return A boolean indicating if the address is an active report oracle.
  function isReportOracle(address _account) public view returns (bool) {
    return reportOracles[_account] && !isReportOracleBlackListed(_account);
  }

  /// @notice Checks if a report oracle is blacklisted.
  /// @param _account Address of the oracle to be checked.
  /// @return A boolean indicating if the address is a blacklisted report oracle.
  function isReportOracleBlackListed(address _account) public view returns (bool) {
    return reportOraclesBlacklist[_account];
  }

  /// @notice Adds a new report oracle.
  /// @dev Only an account with the ORACLE_REPORT_MANAGER_ROLE can call this function.
  /// @param _account Address of the oracle to be added.
  function addReportOracle(address _account) external onlyRole(ORACLE_REPORT_MANAGER_ROLE) {
    if (reportOracles[_account]) revert OracleExists();
    if (reportOraclesBlacklist[_account]) revert OracleBlacklisted();
    if (_account == address(0)) revert ZeroAddress();
    _grantRole(ORACLE_REPORT_ROLE, _account);
    reportOracles[_account] = true;
    totalReportOracles++;
    emit AddReportOracle(_account);
  }

  /// @notice Removes an existing report oracle.
  /// @dev Only an account with the ORACLE_REPORT_MANAGER_ROLE can call this function.
  /// @param _account Address of the oracle to be removed.
  function removeReportOracle(address _account) external onlyRole(ORACLE_REPORT_MANAGER_ROLE) {
    if (!reportOracles[_account]) revert OracleNotExists();
    _revokeRole(ORACLE_REPORT_ROLE, _account);
    reportOracles[_account] = false;
    reportOraclesBlacklist[_account] = false;
    if (!reportOraclesBlacklist[_account]) {
      totalReportOracles--;
    }
    emit RemoveReportOracle(_account);
  }

  /// @notice Blacklists a report oracle.
  /// @dev Only an account with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _account Address of the oracle to be blacklisted.
  function blacklistReportOracle(address _account) external onlyRole(ORACLE_SENTINEL_ROLE) {
    if (!reportOracles[_account]) revert OracleNotExists();
    if (reportOraclesBlacklist[_account]) revert OracleAlreadyBlacklisted();
    reportOraclesBlacklist[_account] = true;
    if (totalReportOracles > 0) {
      totalReportOracles--;
    }
    emit BlacklistReportOracle(_account);
  }

  /// @notice Removes a report oracle from the blacklist.
  /// @dev Only an account with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _account Address of the oracle to be removed from the blacklist.
  function unBlacklistReportOracle(address _account) external onlyRole(ORACLE_SENTINEL_ROLE) {
    if (!reportOracles[_account]) revert OracleNotExists();
    if (!reportOraclesBlacklist[_account]) revert OracleNotBlacklisted();
    reportOraclesBlacklist[_account] = false;

    totalReportOracles++;
    emit UnBlacklistReportOracle(_account);
  }

  /// @notice Adds a new sentinel account.
  /// @dev Only an account with the ADMIN_ROLE can call this function.
  /// @param _account Address of the account to be added as sentinel.
  function addSentinel(address _account) external onlyRole(ADMIN_ROLE) {
    if (hasRole(ORACLE_SENTINEL_ROLE, _account)) revert SentinelExists();
    if (_account == address(0)) revert ZeroAddress();
    grantRole(ORACLE_SENTINEL_ROLE, _account);
  }

  /// @notice Removes an existing sentinel account.
  /// @dev Only an account with the ADMIN_ROLE can call this function.
  /// @param _account Address of the sentinel account to be removed.
  function removeSentinel(address _account) external onlyRole(ADMIN_ROLE) {
    if (!hasRole(ORACLE_SENTINEL_ROLE, _account)) revert SentinelNotExists();
    revokeRole(ORACLE_SENTINEL_ROLE, _account);
  }

  /************
   ** REPORT **
   ************/

  /// @notice Submit a report for the current reporting block.
  /// @dev Handles report submissions, checking for consensus or thresholds and preps next block if needed.
  /// It uses a combination of total votes for report to determine consensus.
  /// @param _report Data structure of the report.
  function submitReport(Report calldata _report) external whenNotPaused activeReportOracle {
    bytes32 hash = isReadyToSubmit(_report);

    reports[reportBlock][hash].push(msg.sender);
    reportForBlock[reportBlock][msg.sender] = true;
    reportVotesForBlock[reportBlock][hash]++;
    totalVotes[reportBlock]++;

    if (consensusReport[reportBlock] == bytes32(0)) {
      uint256 votesBeforeThreshold = totalReportOracles - config.reportNoConsensusMargin;

      if (totalVotes[reportBlock] >= config.oracleQuorum) {
        if (reportVotesForBlock[reportBlock][hash] >= config.oracleQuorum) {
          consensusReport[reportBlock] = hash;
          lastConsensusBlock = reportBlock;
          reportDelayBlock[reportBlock] = block.number;
          pendingExecution = true;
          emit ConsensusApprove(reportBlock, _report);
        }
      }

      if (
        totalVotes[reportBlock] >= votesBeforeThreshold &&
        reportVotesForBlock[reportBlock][hash] < config.oracleQuorum
      ) {
        emit ConsensusFail(reportBlock, _report);
        _advanceNextReportBlock();
      }
    }

    emit SubmitReport(msg.sender, _report);
  }

  /// @notice Allows an active report oracle to execute an approved report.
  /// @dev Executes the actions based on the consensus-approved report.
  /// @param _report The data structure containing report details.
  function executeReport(Report calldata _report) external nonReentrant whenNotPaused activeReportOracle {
    bytes32 hash = isReadyToExecute(_report);

    executedReports[reportBlock][hash] = true;
    lastExecutedBlock = reportBlock;
    pendingExecution = false;
    emit ExecuteReport(msg.sender, reportBlock, _report);

    uint256 currentReportBlock = reportBlock;
    _advanceNextReportBlock();

    if (_report.merkleRoot != bytes32(0)) {
      airdrop.addMerkleRoot(currentReportBlock, _report.merkleRoot);
    }

    if (_report.profitAmount > 0) {
      stakeTogether.processFeeRewards{ value: _report.profitAmount }(_report.profitShares);
    }

    if (_report.lossAmount > 0 || _report.withdrawAmount > 0 || _report.withdrawRefundAmount > 0) {
      uint256 updatedBalance = stakeTogether.beaconBalance() -
        (_report.lossAmount + _report.withdrawAmount + _report.withdrawRefundAmount);
      stakeTogether.setBeaconBalance{ value: _report.withdrawRefundAmount }(updatedBalance);
    }

    if (_report.withdrawAmount > 0) {
      stakeTogether.setWithdrawBalance(stakeTogether.withdrawBalance() - _report.withdrawAmount);
      withdrawals.receiveWithdrawEther{ value: _report.withdrawAmount }();
    }
  }

  /// @notice Advances to the next report block based on the current block number and report frequency.
  /// @dev Computes the next report block and updates the state variable 'reportBlock'.
  /// @return The next report block number.
  function _advanceNextReportBlock() private returns (uint256) {
    uint256 intervalsPassed = Math.mulDiv(block.number, 1, config.reportFrequency);
    uint256 nextReportBlock = Math.mulDiv(intervalsPassed + 1, config.reportFrequency, 1);
    emit AdvanceNextBlock(reportBlock, nextReportBlock);
    reportBlock = nextReportBlock;
    return reportBlock;
  }

  /// @dev Internal function to handle the revoking of consensus reports.
  /// Ensures that the report exists, hasn't been revoked, and the block number is greater than the last executed one.
  /// @param _reportBlock The block number of the report to be revoked.
  function _revokeConsensusReport(uint256 _reportBlock) private {
    if (revokedReports[_reportBlock]) revert ReportRevoked();
    if (_reportBlock <= lastExecutedBlock) revert ReportBlockShouldBeGreater();
    revokedReports[_reportBlock] = true;
    pendingExecution = false;
    emit RevokeConsensusReport(msg.sender, _reportBlock);
    _advanceNextReportBlock();
  }

  /// @notice Force to advance to the next reportBlock.
  function forceNextReportBlock() external activeReportOracle {
    if (block.number <= reportBlock + config.reportFrequency) revert ConsensusNotDelayed();
    if (pendingExecution) revert PendingExecution();
    _revokeConsensusReport(reportBlock);
  }

  // @notice Revokes a consensus-approved report for a given report block.
  /// @dev Only accounts with the ORACLE_SENTINEL_ROLE can call this function.
  /// @param _reportBlock The report block for which the report was approved.
  function revokeConsensusReport(uint256 _reportBlock) external onlyRole(ORACLE_SENTINEL_ROLE) {
    if (consensusReport[_reportBlock] == bytes32(0)) revert NoActiveConsensus();
    if (!pendingExecution) revert NoPendingExecution();
    _revokeConsensusReport(_reportBlock);
  }

  /// @notice Computes and returns the hash of a given report.
  /// @param _report The data structure containing report details.
  /// @return The keccak256 hash of the report.
  function getReportHash(Report calldata _report) external pure returns (bytes32) {
    return keccak256(abi.encode(_report));
  }

  /// @notice Validates if conditions to submit a report for an block report are met.
  /// @dev Verifies conditions such as block number, consensus block report, executed reports, and oracle votes.
  /// @param _report The data structure containing report details.
  /// @return The keccak256 hash of the report.
  function isReadyToSubmit(Report calldata _report) public view returns (bytes32) {
    bytes32 hash = keccak256(abi.encode(_report));
    if (totalReportOracles < config.oracleQuorum) revert QuorumNotReached();
    if (block.number <= reportBlock) revert BlockNumberNotReached();
    if (executedReports[reportBlock][hash]) revert AlreadyExecuted();
    if (reportForBlock[reportBlock][msg.sender]) revert OracleAlreadyReported();
    if (pendingExecution) revert PendingExecution();
    if (config.reportFrequency <= 0) revert ConfigNotSet();

    if (config.reportNoConsensusMargin > 0) {
      if (config.reportNoConsensusMargin >= totalReportOracles - config.oracleQuorum) {
        revert IncreaseOraclesToUseMargin();
      }
    }

    return hash;
  }

  /// @notice Validates if conditions to execute a report are met.
  /// @dev Verifies conditions like revoked reports, executed reports, consensus reports, and beacon balance.
  /// @param _report The data structure containing report details.
  /// @return The keccak256 hash of the report.
  function isReadyToExecute(Report calldata _report) public view returns (bytes32) {
    bytes32 hash = keccak256(abi.encode(_report));
    if (totalReportOracles < config.oracleQuorum) revert QuorumNotReached();
    if (revokedReports[reportBlock]) revert ReportRevoked();
    if (executedReports[reportBlock][hash]) revert AlreadyExecuted();
    if (consensusReport[reportBlock] != hash) revert NoActiveConsensus();
    if (block.number < reportDelayBlock[reportBlock] + config.reportDelayBlock) revert EarlyExecution();
    if (_report.lossAmount + _report.withdrawRefundAmount > stakeTogether.beaconBalance())
      revert BeaconBalanceTooLow();
    if (_report.withdrawAmount > stakeTogether.withdrawBalance()) revert WithdrawBalanceTooLow();
    if (
      address(this).balance <
      (_report.profitAmount + _report.withdrawAmount + _report.withdrawRefundAmount)
    ) revert InsufficientEthBalance();
    if (!pendingExecution) revert NoPendingExecution();
    if (config.reportFrequency == 0) revert ConfigNotSet();
    return hash;
  }
}
