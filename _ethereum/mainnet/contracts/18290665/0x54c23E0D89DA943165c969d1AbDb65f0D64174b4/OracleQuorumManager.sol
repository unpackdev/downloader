// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ProtocolEvents.sol";
import "./Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./IOracle.sol";

interface OracleQuorumManagerEvents {
    /// @notice Emitted when a record has passed quorum and was submitted to the oracle.
    /// @param block The block the record was finalized on.
    event ReportQuorumReached(uint64 indexed block);

    /// @notice Emitted when a record has been reported by a reporter.
    /// @param block The block the record was recorded on.
    /// @param reporter The reporter that reported the record.
    /// @param recordHash The hash of the record that was reported.
    /// @param record The record that was received.
    event ReportReceived(
        uint64 indexed block, address indexed reporter, bytes32 indexed recordHash, OracleRecord record
    );

    /// @notice Emitted when the oracle failed to receive a record from the oracle quorum manager.
    /// @param reason The reason for the failure, i.e. the caught error.
    event OracleRecordReceivedError(bytes reason);
}

/// @title OracleQuorumManager
/// @notice Responsible for managing the quorum of oracle reporters.
contract OracleQuorumManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    OracleQuorumManagerEvents,
    ProtocolEvents
{
    error InvalidReporter();
    error AlreadyReporter();
    error RelativeThresholdExceedsOne();

    /// @notice Oracle manager role can update properties in the OracleQuorumManager.
    bytes32 public constant QUORUM_MANAGER_ROLE = keccak256("QUORUM_MANAGER_ROLE");

    /// @notice Any reporter modifier can change the set of oracle services which can produce a valid
    /// oracle report. This means that this is quite a crucial role and should have elevated access
    /// requirements.
    bytes32 public constant REPORTER_MODIFIER_ROLE = keccak256("REPORTER_MODIFIER_ROLE");

    /// @notice The service oracle reporter role is used to identify which oracle services can
    /// produce a valid oracle report. Note that granting this role to an address may have consequences
    /// for the logic of the contract - e.g. the contract may calculate quorum based on the number of
    /// members in this set. So you should not add the role to anything other than an oracle service.
    /// @dev To discover all oracle services, you can use `getRoleMemberCount`and
    /// getRoleMember(role, N)` (on the same block).
    bytes32 public constant SERVICE_ORACLE_REPORTER = keccak256("SERVICE_ORACLE_REPORTER");

    /// @dev A basis point (often denoted as bp, 1bp = 0.01%) is a unit of measure used in finance to describe
    /// the percentage change in a financial instrument. This is a constant value set as 10000 which represents
    /// 100% in basis point terms.
    uint16 internal constant _BASIS_POINTS_DENOMINATOR = 10000;

    /// @notice Oracle to finalize reports for.
    IOracle public oracle;

    /// @notice Report hashes by block by reporter.
    /// This can be used for a reporter to verify a record computation and update it in case of an error.
    mapping(uint64 block => mapping(address reporter => bytes32 recordHash)) public reporterRecordHashesByBlock;

    /// @notice The number of times a record hash has been reported for a block.
    mapping(uint64 block => mapping(bytes32 recordHash => uint256)) public recordHashCountByBlock;

    /// @notice The target number of blocks in a report window.
    uint64 public targetReportWindowBlocks;

    /// @notice The absolute number of reporters that have to submit the same report for it to be accepted.
    uint16 public absoluteThreshold;

    /// @notice The relative number of reporters (in basis points) that have to submit the same report for it to be
    /// accepted. It is a value between 0 and 10000 basis points (i.e., 0 to 100%). It's used to determine what
    /// proportion of the total number of reporters need to agree on a report for it to be accepted.
    /// @dev Scaled with `getRoleMemberCount(SERVICE_ORACLE_REPORTER)`.
    uint16 public relativeThresholdBasisPoints;

    /// @notice Configuration for contract initialization.
    struct Init {
        address admin;
        address reporterModifier;
        address manager;
        address[] allowedReporters;
        IOracle oracle;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Inititalizes the contract.
    /// @dev MUST be called during the contract upgrade to set up the proxies state.
    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(REPORTER_MODIFIER_ROLE, init.reporterModifier);
        _setRoleAdmin(SERVICE_ORACLE_REPORTER, REPORTER_MODIFIER_ROLE);

        _grantRole(QUORUM_MANAGER_ROLE, init.manager);

        oracle = init.oracle;
        uint256 len = init.allowedReporters.length;
        for (uint256 i = 0; i < len; i++) {
            _grantRole(SERVICE_ORACLE_REPORTER, init.allowedReporters[i]);
        }

        // Assumes that a block is created every 12 seconds.
        // Might be slightly longer than the 8 hours target in practice as slots can be empty.
        targetReportWindowBlocks = 8 hours / 12 seconds;

        absoluteThreshold = 1;
        relativeThresholdBasisPoints = 0;
    }

    /// @notice Determines if a given record hash has reached quorum for a given block.
    /// @dev True if the number of reporters agreeing on the record hash is greater than or equal to the absolute and
    /// relative threshold.
    /// @param blockNumber The block number.
    /// @param recordHash The record hash.
    function _hasReachedQuroum(uint64 blockNumber, bytes32 recordHash) internal view returns (bool) {
        uint256 numReports = recordHashCountByBlock[blockNumber][recordHash];
        uint256 numReporters = getRoleMemberCount(SERVICE_ORACLE_REPORTER);

        return (numReports >= absoluteThreshold)
            && (numReports * _BASIS_POINTS_DENOMINATOR >= numReporters * relativeThresholdBasisPoints);
    }

    /// @notice Determines if a record with given end block number has already been received by the oracle.
    /// @dev This includes added and pending records.
    /// @param updateEndBlock The end block number.
    function _wasReceivedByOracle(uint256 updateEndBlock) internal view returns (bool) {
        return oracle.latestRecord().updateEndBlock >= updateEndBlock
            || (oracle.hasPendingUpdate() && oracle.pendingUpdate().updateEndBlock >= updateEndBlock);
    }

    /// @notice Returns the record hash for a given block and reporter.
    /// @param blockNumber The block number.
    /// @param sender The reporter.
    function recordHashByBlockAndSender(uint64 blockNumber, address sender) external view returns (bytes32) {
        return reporterRecordHashesByBlock[blockNumber][sender];
    }

    /// @notice Tracks received records to determine consensus.
    /// @param reporter The address of the off-chain service that submitted the record.
    /// @param record The received record.
    function _trackReceivedRecord(address reporter, OracleRecord calldata record) internal returns (bytes32) {
        bytes32 newHash = keccak256(abi.encode(record));
        emit ReportReceived(record.updateEndBlock, reporter, newHash, record);

        bytes32 previousHash = reporterRecordHashesByBlock[record.updateEndBlock][reporter];
        if (newHash == previousHash) {
            return newHash;
        }

        if (previousHash != 0) {
            recordHashCountByBlock[record.updateEndBlock][previousHash] -= 1;
        }

        // Record the hash of the data for this report.
        recordHashCountByBlock[record.updateEndBlock][newHash] += 1;
        reporterRecordHashesByBlock[record.updateEndBlock][reporter] = newHash;

        return newHash;
    }

    /// @notice Receives an oracle report.
    /// @dev This function should be called by the oracle service.
    /// We explicitly allow oracles to 'update' their report for a given block. This allows repairs
    /// in the case of inconsistency without requiring a new window to be started.
    /// This function deliberately never reverts to log all reports received as events for off-chain performance metrics
    /// and to simplify the interaction with the oracle services.
    /// @param record The new oracle record update.
    function receiveRecord(OracleRecord calldata record) external onlyRole(SERVICE_ORACLE_REPORTER) {
        bytes32 recordHash = _trackReceivedRecord(msg.sender, record);

        if (!_hasReachedQuroum(record.updateEndBlock, recordHash)) {
            return;
        }

        if (_wasReceivedByOracle(record.updateEndBlock)) {
            // This branch will be taken if the reporter submits their report after quorum has already been reached,
            // e.g. the 3rd reporter in a 2/3 threshold setting.
            return;
        }

        emit ReportQuorumReached(record.updateEndBlock);

        // Deliberately not reverting to simplify the integration in off-chain oracle services, but wrapping any oracle
        // errors as events for observability.
        try oracle.receiveRecord(record) {}
        catch (bytes memory reason) {
            emit OracleRecordReceivedError(reason);
        }
    }

    /// @notice Sets the target report window size in the number of blocks.
    /// @param newTargetReportWindowBlocks The new target report window size in blocks.
    /// NOTE: Setting this lower than the minimum report size as defined by the oracle is technically valid,
    /// but will result in a failing sanity check.
    function setTargetReportWindowBlocks(uint64 newTargetReportWindowBlocks) external onlyRole(QUORUM_MANAGER_ROLE) {
        targetReportWindowBlocks = newTargetReportWindowBlocks;
        emit ProtocolConfigChanged(
            this.setTargetReportWindowBlocks.selector,
            "setTargetReportWindowBlocks(uint64)",
            abi.encode(newTargetReportWindowBlocks)
        );
    }

    /// @notice Sets the absolute and relative thresholds (i.e. the number of reporters that have to agree) for a report
    /// to be accepted.
    /// @param absoluteThreshold_ The new absolute threshold which sets the absoluteThreshold.
    /// See also {absoluteThreshold}
    /// @param relativeThresholdBasisPoints_ The new relative threshold in basis points which sets the
    /// relativeThresholdBasisPoints.
    /// See also {relativeThresholdBasisPoints}
    function setQuorumThresholds(uint16 absoluteThreshold_, uint16 relativeThresholdBasisPoints_)
        external
        onlyRole(QUORUM_MANAGER_ROLE)
    {
        if (relativeThresholdBasisPoints_ > _BASIS_POINTS_DENOMINATOR) {
            revert RelativeThresholdExceedsOne();
        }

        emit ProtocolConfigChanged(
            this.setQuorumThresholds.selector,
            "setQuorumThresholds(uint16,uint16)",
            abi.encode(absoluteThreshold_, relativeThresholdBasisPoints_)
        );
        absoluteThreshold = absoluteThreshold_;
        relativeThresholdBasisPoints = relativeThresholdBasisPoints_;
    }
}
