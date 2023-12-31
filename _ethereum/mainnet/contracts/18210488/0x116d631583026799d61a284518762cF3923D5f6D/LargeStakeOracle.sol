// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "./BaseOracle.sol";
import "./ILargeStaking.sol";
import "./ConsensusStruct.sol";

contract LargeStakeOracle is BaseOracle {
    event LargeStakeContractChanged(address oldLargeStake, address newLargeStake);
    event ReportSuccess(
        uint256 indexed refSlot,
        uint256 consensusVersion,
        CLStakingExitInfo[] cLStakingExitInfos,
        CLStakingSlashInfo[] cLStakingSlashInfos
    );
    event UpdateExitLimit(uint256 oldExitLimit, uint256 newExitLimit);

    error ReportDataIsEmpty();
    error ExitLimitNotZero();
    error OverExitLimit();

    struct ProcessingState {
        /// @notice Reference slot for the current reporting frame.
        uint256 currentFrameRefSlot;
        /// @notice The last time at which a report data can be submitted for the current
        /// reporting frame.
        uint256 processingDeadlineTime;
        /// @notice Hash of the report data. Zero bytes if consensus on the hash hasn't
        /// been reached yet for the current reporting frame.
        bytes32 dataHash;
        /// @notice Whether any report data for the for the current reporting frame has been
        /// already submitted.
        bool dataSubmitted;
    }

    /// Data provider interface
    struct ReportData {
        // @dev Version of the oracle consensus rules. Current version expected
        // by the oracle can be obtained by calling getConsensusVersion().
        uint256 consensusVersion;
        // @dev Reference slot for which the report was calculated. If the slot
        // contains a block, the exitBlockNumbers being reported should include all state
        // changes resulting from that block. The epoch containing the slot
        // should be finalized prior to calculating the report.
        // beacon slot for reference
        uint256 refSlot;
        // @dev Validator quits reporting information.
        // Only validator exits are reported.
        CLStakingExitInfo[] clStakingExitInfos;
        // @dev Verifier slash reporting information.
        // Only validator slash are reported.
        CLStakingSlashInfo[] clStakingSlashInfos;
    }

    address public largeStakeContract;

    // Specifies the maximum number of validator exits reported each time
    uint256 public exitLimit;

    function initialize(
        uint256 secondsPerSlot,
        uint256 genesisTime,
        address consensusContract,
        uint256 consensusVersion,
        uint256 lastProcessingRefSlot,
        address _dao,
        address _largeStakeContract
    ) public initializer {
        __BaseOracle_init(secondsPerSlot, genesisTime, consensusContract, consensusVersion, lastProcessingRefSlot, _dao);
        largeStakeContract = _largeStakeContract;
        exitLimit = 100;
    }

    /// Set the number limit for the validator to report
    function setExitLimit(uint256 _exitLimit) external onlyDao {
        if (_exitLimit == 0) revert ExitLimitNotZero();
        emit UpdateExitLimit(exitLimit, _exitLimit);
        exitLimit = _exitLimit;
    }

    /**
     * @notice set LargeStake contract address
     */
    function setLargeStakeContract(address _largeStakeContractAddress) external onlyDao {
        if (_largeStakeContractAddress == address(0)) revert InvalidAddr();
        emit LargeStakeContractChanged(largeStakeContract, _largeStakeContractAddress);
        largeStakeContract = _largeStakeContractAddress;
    }

    /// @notice Returns data processing state for the current reporting frame.
    /// @return result See the docs for the `ProcessingState` struct.
    function getProcessingState() external view returns (ProcessingState memory result) {
        ConsensusReport memory report = consensusReport;
        result.currentFrameRefSlot = _getCurrentRefSlot();

        if (result.currentFrameRefSlot != report.refSlot) {
            return result;
        }

        result.processingDeadlineTime = report.processingDeadlineTime;
        result.dataHash = report.hash;

        result.dataSubmitted = lastProcessingRefSlot == result.currentFrameRefSlot;
        if (!result.dataSubmitted) {
            return result;
        }
    }

    /// @notice Submits report data for processing.
    ///
    /// @param data The data. See the `ReportData` structure's docs for details.
    /// @param _contractVersion Expected version of the oracle contract.
    /// @param _moduleId oracle module id.
    function submitReportData(ReportData calldata data, uint256 _contractVersion, uint256 _moduleId)
        external
        whenNotPaused
    {
        _checkMsgSenderIsAllowedToSubmitData();
        _checkContractVersion(_contractVersion);
        // it's a waste of gas to copy the whole calldata into mem but seems there's no way around
        _checkConsensusData(data.refSlot, data.consensusVersion, keccak256(abi.encode(data)), _moduleId);
        _startProcessing();
        _handleConsensusReportData(data);
    }

    function _handleConsensusReportData(ReportData calldata data) internal {
        if (data.clStakingExitInfos.length == 0 && data.clStakingSlashInfos.length == 0) {
            revert ReportDataIsEmpty();
        }
        if (data.clStakingExitInfos.length > exitLimit || data.clStakingSlashInfos.length > exitLimit) {
            revert OverExitLimit();
        }
        ILargeStaking(largeStakeContract).reportCLStakingData(data.clStakingExitInfos, data.clStakingSlashInfos);

        emit ReportSuccess(data.refSlot, data.consensusVersion, data.clStakingExitInfos, data.clStakingSlashInfos);
    }

    /// @notice Called when oracle gets a new consensus report from the HashConsensus contract.
    ///
    /// Keep in mind that, until you call `_startProcessing`, the oracle committee is free to
    /// reach consensus on another report for the same reporting frame and re-submit it using
    /// this function.
    ///
    function _handleConsensusReport(
        ConsensusReport memory report,
        uint256 prevSubmittedRefSlot,
        uint256 prevProcessingRefSlot
    ) internal override {}
}
