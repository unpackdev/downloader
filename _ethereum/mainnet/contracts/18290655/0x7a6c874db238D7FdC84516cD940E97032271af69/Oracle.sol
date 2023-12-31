// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Initializable.sol";
import {AccessControlEnumerableUpgradeable} from
    "openzeppelin-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./Math.sol";

import "./ProtocolEvents.sol";
import "./IOracle.sol";
import "./IStaking.sol";
import "./IReturnsAggregator.sol";
import "./IPauser.sol";

/// @notice Events emitted by the oracle contract.
interface OracleEvents {
    /// @notice Emitted when a new oracle record was added to the list of oracle records. A pending record will only
    /// emit this event if it was accepted by the admin.
    /// @param index The index of the new record.
    /// @param record The new record that was added to the list.
    event OracleRecordAdded(uint256 indexed index, OracleRecord record);

    /// @notice Emitted when a record has been modified.
    /// @param index The index of the record that was modified.
    /// @param record The newly modified record.
    event OracleRecordModified(uint256 indexed index, OracleRecord record);

    /// @notice Emitted when a pending update has been rejected.
    /// @param pendingUpdate The rejected pending update.
    event OraclePendingUpdateRejected(OracleRecord pendingUpdate);

    /// @notice Emitted when the oracle's record did not pass a sanity check.
    /// @param reasonHash The hash of the reason for the record rejection.
    /// @param reason The reason for the record rejection.
    /// @param record The record that was rejected.
    /// @param value The value that violated a bound.
    /// @param bound The bound of the rejected update.
    event OracleRecordFailedSanityCheck(
        bytes32 indexed reasonHash, string reason, OracleRecord record, uint256 value, uint256 bound
    );
}

/// @title Oracle
/// @notice The oracle contract stores records which are snapshots of consensus layer state over discrete periods of
/// time. These records provide consensus layer data to the protocol's onchain contracts for their accounting logic.
contract Oracle is Initializable, AccessControlEnumerableUpgradeable, IOracle, OracleEvents, ProtocolEvents {
    // Errors.
    error CannotUpdateWhileUpdatePending();
    error CannotModifyInitialRecord();
    error InvalidConfiguration();
    error InvalidRecordModification();
    error InvalidUpdateStartBlock(uint256 wantUpdateStartBlock, uint256 gotUpdateStartBlock);
    error InvalidUpdateEndBeforeStartBlock(uint256 end, uint256 start);
    error InvalidUpdateMoreDepositsProcessedThanSent(uint256 processed, uint256 sent);
    error InvalidUpdateMoreValidatorsThanInitiated(uint256 numValidatorsOnRecord, uint256 numInitiatedValidators);
    error NoUpdatePending();
    error Paused();
    error RecordDoesNotExist(uint256 idx);
    error UnauthorizedOracleUpdater(address sender, address oracleUpdater);
    error UpdateEndBlockNumberNotFinal(uint256 updateFinalizingBlock);
    error ZeroAddress();

    /// @notice Role allowed to modify the settable properties on the contract.
    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    /// @notice Role allowed to modify an existing oracle record.
    bytes32 public constant ORACLE_MODIFIER_ROLE = keccak256("ORACLE_MODIFIER_ROLE");

    /// @notice Role allowed to resolve or replace pending oracle updates which have failed the sanity check.
    bytes32 public constant ORACLE_PENDING_UPDATE_RESOLVER_ROLE = keccak256("ORACLE_PENDING_UPDATE_RESOLVER_ROLE");

    /// @notice Finalization block number delta upper bound for the setter.
    uint256 internal constant _FINALIZATION_BLOCK_NUMBER_DELTA_UPPER_BOUND = 2048;

    /// @notice Stores the oracle records.
    /// @dev Must not be pushed directly to, use `_pushRecord` instead.
    OracleRecord[] internal _records;

    /// @inheritdoc IOracleReadPending
    bool public hasPendingUpdate;

    /// @notice The pending oracle update, if it was rejected by `_sanityCheckUpdate`.
    /// @dev Undefined if `hasPendingUpdate` is false.
    OracleRecord internal _pendingUpdate;

    // @notice The number of blocks which must have passed before we accept an oracle update to ensure that the analysed
    // period is finalised.
    // NOTE: We cannot make guarantees about the consensus layer's state, but it is expected that
    // finalisation takes 2 epochs.
    uint256 public finalizationBlockNumberDelta;

    /// @notice The address allowed to push oracle updates.
    address public oracleUpdater;

    /// @notice The pauser contract.
    /// @dev Keeps the pause state across the protocol.
    IPauser public pauser;

    /// @notice The staking contract.
    /// @dev Quantities tracked by the staking contract during validator initiation are used to sanity check oracle
    /// updates.
    IStakingInitiationRead public staking;

    /// @notice The aggregator contract.
    /// @dev Called when pushing an oracle record to process.
    IReturnsAggregatorWrite public aggregator;

    //
    // Sanity check parameters
    //

    /// @notice The minimum deposit per new validator (on average).
    /// @dev This is used to put constraints on the reported processed deposits. Even thought this will foreseeably be
    /// 32 ETH, we keep it as a configurable parameter to allow for future changes.
    uint256 public minDepositPerValidator;

    /// @notice The maximum deposit per new validator (on average).
    /// @dev This is used to put constraints on the reported processed deposits. Even thought this will foreseeably be
    /// 32 ETH, we keep it as a configurable parameter to allow for future changes.
    uint256 public maxDepositPerValidator;

    /// @notice The minimum consensus layer gain per block (in part-per-trillion, i.e. in units of 1e-12).
    /// @dev This is used to put constraints on the reported change of the total consensus layer balance.
    uint40 public minConsensusLayerGainPerBlockPPT;

    /// @notice The maximum consensus layer gain per block (in part-per-trillion, i.e. in units of 1e-12).
    /// @dev This is used to put constraints on the reported change of the total consensus layer balance.
    uint40 public maxConsensusLayerGainPerBlockPPT;

    /// @notice The maximum consensus layer loss (in part-per-million, i.e. in units of 1e-6).
    /// This value doesn't scale with time and represents a total loss over a given period, remaining independent of the
    /// blocks. It encapsulates scenarios such as a single substantial slashing event or concurrent off-chain oracle
    /// service downtime with validators incurring attestation penalties.
    /// @dev This is used to put constraints on the reported change of the total consensus layer balance.
    uint24 public maxConsensusLayerLossPPM;

    /// @notice The minimum report size to allow for any report.
    /// @dev This value helps defend against the extreme bounds of checks in the case of malicious oracles.
    uint16 public minReportSizeBlocks;

    /// @notice The denominator of a parts-per-million (PPM) fraction.
    uint24 internal constant _PPM_DENOMINATOR = 1e6;

    /// @notice The denominator of a parts-per-trillion (PPT) fraction.
    uint40 internal constant _PPT_DENOMINATOR = 1e12;

    /// @notice Configuration for contract initialization.
    struct Init {
        address admin;
        address manager;
        address oracleUpdater;
        address pendingResolver;
        IReturnsAggregatorWrite aggregator;
        IPauser pauser;
        IStakingInitiationRead staking;
    }

    constructor() {
        _disableInitializers();
    }

    /// @notice Inititalizes the contract.
    /// @dev MUST be called during the contract upgrade to set up the proxies state.
    function initialize(Init memory init) external initializer {
        __AccessControlEnumerable_init();

        // We intentionally do not assign an address to the ORACLE_MODIFIER_ROLE. This is to prevent
        // unintentional oracle modifications outside of exceptional circumstances.
        _grantRole(DEFAULT_ADMIN_ROLE, init.admin);
        _grantRole(ORACLE_MANAGER_ROLE, init.manager);
        _grantRole(ORACLE_PENDING_UPDATE_RESOLVER_ROLE, init.pendingResolver);

        aggregator = init.aggregator;
        oracleUpdater = init.oracleUpdater;
        pauser = init.pauser;
        staking = init.staking;

        // Assumes 2 epochs (in blocks).
        finalizationBlockNumberDelta = 64;

        minReportSizeBlocks = 100;
        minDepositPerValidator = 32 ether;
        maxDepositPerValidator = 32 ether;

        // 7200 slots per day * 365 days per year = 2628000 slots per year
        // assuming 5% yield per year
        // 5% / 2628000 = 1.9025e-8
        // 1.9025e-8 per slot = 19025 PPT
        maxConsensusLayerGainPerBlockPPT = 190250; // 10x approximate rate
        minConsensusLayerGainPerBlockPPT = 1903; // 0.1x approximate rate

        // We chose a lower bound of a 0.1% loss for the protocol based on several factors:
        //
        // - Sanity check should not fail for normal operations where we define normal operations as attestation
        // penalties due to offline validators. Supposing all our validators go offline, the protocol is expected
        // to have a 0.03% missed attestation penalty on mainnet for all validators' balance for a single day.
        // - For a major slashing event, (i.e. 1 ETH slashed for half of our validators), we should expect a drop of
        // 1.56% of the entire protocol. This *must* trigger the consensus layer loss lower bound.
        maxConsensusLayerLossPPM = 1000;

        // Initializing the oracle with a zero record, so that all contract functions (e.g. `latestRecord`) work as
        // expected. We set updateEndBlock to be the block at which the staking contract was initialized, so that the
        // first time an Oracle computes a report, it doesn't bother looking at blocks earlier than when the protocol
        // was deployed. That would be a waste, as our system would not have been running then.
        _pushRecord(OracleRecord(0, uint64(staking.initializationBlockNumber()), 0, 0, 0, 0, 0, 0));
    }

    /// @inheritdoc IOracleWrite
    /// @dev Reverts if the update is invalid. If the update is valid but does not pass the `_sanityCheckUpdate`, the
    /// update is marked as pending and must be approved or replaced by the `ORACLE_PENDING_UPDATE_RESOLVER_ROLE`. If
    /// the update fails the sanity check, it will also pause the protocol.
    /// @param newRecord The oracle record to update to.
    function receiveRecord(OracleRecord calldata newRecord) external {
        if (pauser.isSubmitOracleRecordsPaused()) {
            revert Paused();
        }

        if (msg.sender != oracleUpdater) {
            revert UnauthorizedOracleUpdater(msg.sender, oracleUpdater);
        }

        if (hasPendingUpdate) {
            revert CannotUpdateWhileUpdatePending();
        }

        validateUpdate(_records.length - 1, newRecord);

        uint256 updateFinalizingBlock = newRecord.updateEndBlock + finalizationBlockNumberDelta;
        if (block.number < updateFinalizingBlock) {
            revert UpdateEndBlockNumberNotFinal(updateFinalizingBlock);
        }

        (string memory rejectionReason, uint256 value, uint256 bound) = sanityCheckUpdate(latestRecord(), newRecord);
        if (bytes(rejectionReason).length > 0) {
            _pendingUpdate = newRecord;
            hasPendingUpdate = true;
            emit OracleRecordFailedSanityCheck({
                reasonHash: keccak256(bytes(rejectionReason)),
                reason: rejectionReason,
                record: newRecord,
                value: value,
                bound: bound
            });
            // Failing the sanity check will pause the protocol providing the admins time to accept or reject the
            // pending update.
            pauser.pauseAll();
            return;
        }

        _pushRecord(newRecord);
    }

    /// @notice Modifies an existing record's balances due to errors or malicious behavior. Modifiying the latest
    /// oracle record will have an effect on the total controlled supply, thereby altering the exchange rate.
    /// Note that users who have already requested to unstake, and are in the queue, will not be affected by the new
    /// exchange rate.
    /// @dev This function should only be called in an emergency situation where the oracle has posted an invalid
    /// record, either due to a calculations issue (or in the unlikely event of a compromise). If the new record
    /// reports higher returns in the window, then we need to reprocess the difference. If the new record reports
    /// lower returns in the window, then we need to top up the difference in the consensusLayerReceiver wallet. Without
    /// adding the missing funds in the consensusLayerReceiver wallet this function will revert in the future.
    /// @param idx The index of the oracle record to modify.
    /// @param record The new oracle record that will modify the existing one.
    function modifyExistingRecord(uint256 idx, OracleRecord calldata record) external onlyRole(ORACLE_MODIFIER_ROLE) {
        if (idx == 0) {
            revert CannotModifyInitialRecord();
        }

        if (idx >= _records.length) {
            revert RecordDoesNotExist(idx);
        }

        OracleRecord storage existingRecord = _records[idx];
        // Cannot modify the bounds of the record to prevent gaps in the
        // records.
        if (
            existingRecord.updateStartBlock != record.updateStartBlock
                || existingRecord.updateEndBlock != record.updateEndBlock
        ) {
            revert InvalidRecordModification();
        }

        validateUpdate(idx - 1, record);

        // If the new record has a higher windowWithdrawnRewardAmount or windowWithdrawnPrincipalAmount, we need to
        // process the difference. If this is the case, then when we processed the event, we didn't take enough from
        // the consensus layer returns wallet.
        uint256 missingRewards = 0;
        uint256 missingPrincipals = 0;

        if (record.windowWithdrawnRewardAmount > existingRecord.windowWithdrawnRewardAmount) {
            missingRewards = record.windowWithdrawnRewardAmount - existingRecord.windowWithdrawnRewardAmount;
        }
        if (record.windowWithdrawnPrincipalAmount > existingRecord.windowWithdrawnPrincipalAmount) {
            missingPrincipals = record.windowWithdrawnPrincipalAmount - existingRecord.windowWithdrawnPrincipalAmount;
        }

        _records[idx] = record;
        emit OracleRecordModified(idx, record);

        // Move external call to the end to avoid any reentrancy issues.
        if (missingRewards > 0 || missingPrincipals > 0) {
            aggregator.processReturns({
                rewardAmount: missingRewards,
                principalAmount: missingPrincipals,
                shouldIncludeELRewards: false
            });
        }
    }

    /// @notice Check that the new oracle record is technically valid by comparing it to the previous
    /// record.
    /// @dev Reverts if the oracle record fails to pass validation. This is much stricter compared to the sanityCheck
    /// as the validation logic ensures that our oracle invariants are kept intact.
    /// @param prevRecordIndex The index of the previous record.
    /// @param newRecord The oracle record to validate.
    function validateUpdate(uint256 prevRecordIndex, OracleRecord calldata newRecord) public view {
        OracleRecord storage prevRecord = _records[prevRecordIndex];
        if (newRecord.updateEndBlock <= newRecord.updateStartBlock) {
            revert InvalidUpdateEndBeforeStartBlock(newRecord.updateEndBlock, newRecord.updateStartBlock);
        }

        // Ensure that oracle records are aligned i.e. making sure that the new record window picks up where the
        // previous one left off.
        if (newRecord.updateStartBlock != prevRecord.updateEndBlock + 1) {
            revert InvalidUpdateStartBlock(prevRecord.updateEndBlock + 1, newRecord.updateStartBlock);
        }

        // Ensure that the offchain oracle has only tracked deposits from the protocol. The processed deposits on the
        // consensus layer can be at most the amount of ether the protocol has deposited into the deposit contract.
        if (newRecord.cumulativeProcessedDepositAmount > staking.totalDepositedInValidators()) {
            revert InvalidUpdateMoreDepositsProcessedThanSent(
                newRecord.cumulativeProcessedDepositAmount, staking.totalDepositedInValidators()
            );
        }

        if (
            uint256(newRecord.currentNumValidatorsNotWithdrawable)
                + uint256(newRecord.cumulativeNumValidatorsWithdrawable) > staking.numInitiatedValidators()
        ) {
            revert InvalidUpdateMoreValidatorsThanInitiated(
                newRecord.currentNumValidatorsNotWithdrawable + newRecord.cumulativeNumValidatorsWithdrawable,
                staking.numInitiatedValidators()
            );
        }
    }

    /// @notice Sanity checks an incoming oracle update. If it fails, the update is rejected and marked as pending to be
    /// approved or replaced by the `ORACLE_PENDING_UPDATE_RESOLVER_ROLE`.
    /// @dev If the record fails the sanity check, the function does not revert as we want to store the offending oracle
    /// record in a pending state.
    /// @param newRecord The incoming record to check.
    /// @return A tuple containing the reason for the rejection, the value that failed the check and the bound that it
    /// violated. The reason is the empty string if the update is valid.
    function sanityCheckUpdate(OracleRecord memory prevRecord, OracleRecord calldata newRecord)
        public
        view
        returns (string memory, uint256, uint256)
    {
        uint64 reportSize = newRecord.updateEndBlock - newRecord.updateStartBlock + 1;
        {
            //
            // Report size
            //
            // We implement this as a sanity check rather than a validation because the report is technically valid
            // and there may be a feasible reason to accept small report at some point.
            if (reportSize < minReportSizeBlocks) {
                return ("Report blocks below minimum bound", reportSize, minReportSizeBlocks);
            }
        }
        {
            //
            // Number of validators
            //
            // Checks that the total number of validators and the number of validators that are in the withdrawable state
            // did not decrease in the new oracle period.
            if (newRecord.cumulativeNumValidatorsWithdrawable < prevRecord.cumulativeNumValidatorsWithdrawable) {
                return (
                    "Cumulative number of withdrawable validators decreased",
                    newRecord.cumulativeNumValidatorsWithdrawable,
                    prevRecord.cumulativeNumValidatorsWithdrawable
                );
            }
            {
                uint256 prevNumValidators =
                    prevRecord.currentNumValidatorsNotWithdrawable + prevRecord.cumulativeNumValidatorsWithdrawable;
                uint256 newNumValidators =
                    newRecord.currentNumValidatorsNotWithdrawable + newRecord.cumulativeNumValidatorsWithdrawable;

                if (newNumValidators < prevNumValidators) {
                    return ("Total number of validators decreased", newNumValidators, prevNumValidators);
                }
            }
        }

        {
            //
            // Deposits
            //
            // Checks that the total amount of deposits processed by the oracle did not decrease in the new oracle
            // period. It also checks that the amount of newly deposited ETH is possible given how many validators
            // we have included in the new period.
            if (newRecord.cumulativeProcessedDepositAmount < prevRecord.cumulativeProcessedDepositAmount) {
                return (
                    "Processed deposit amount decreased",
                    newRecord.cumulativeProcessedDepositAmount,
                    prevRecord.cumulativeProcessedDepositAmount
                );
            }

            uint256 newDeposits =
                (newRecord.cumulativeProcessedDepositAmount - prevRecord.cumulativeProcessedDepositAmount);
            uint256 newValidators = (
                newRecord.currentNumValidatorsNotWithdrawable + newRecord.cumulativeNumValidatorsWithdrawable
                    - prevRecord.currentNumValidatorsNotWithdrawable - prevRecord.cumulativeNumValidatorsWithdrawable
            );

            if (newDeposits < newValidators * minDepositPerValidator) {
                return (
                    "New deposits below min deposit per validator", newDeposits, newValidators * minDepositPerValidator
                );
            }

            if (newDeposits > newValidators * maxDepositPerValidator) {
                return (
                    "New deposits above max deposit per validator", newDeposits, newValidators * maxDepositPerValidator
                );
            }
        }

        {
            //
            // Consensus layer balance change from the previous period.
            //
            // Checks that the change in the consensus layer balance is within the bounds given by the maximum loss and
            // minimum gain parameters. For example, a major slashing event will cause an out of bounds loss in the
            // consensus layer.

            // The baselineGrossCLBalance represents the expected growth of our validators balance in the new period
            // given no slashings, no rewards, etc. It's used as the baseline in our upper (growth) and lower (loss)
            // bounds calculations.
            uint256 baselineGrossCLBalance = prevRecord.currentTotalValidatorBalance
                + (newRecord.cumulativeProcessedDepositAmount - prevRecord.cumulativeProcessedDepositAmount);

            // The newGrossCLBalance is the actual amount of ETH we have recorded in the consensus layer for the new
            // record period.
            uint256 newGrossCLBalance = newRecord.currentTotalValidatorBalance
                + newRecord.windowWithdrawnPrincipalAmount + newRecord.windowWithdrawnRewardAmount;

            {
                // Relative lower bound on the net decrease of ETH on the consensus layer.
                // Depending on the parameters the loss term might completely dominate over the minGain one.
                //
                // Using a minConsensusLayerGainPerBlockPPT greater than 0, the lower bound becomes an upward slope.
                // Setting minConsensusLayerGainPerBlockPPT, the lower bound becomes a constant.
                uint256 lowerBound = baselineGrossCLBalance
                    - Math.mulDiv(maxConsensusLayerLossPPM, baselineGrossCLBalance, _PPM_DENOMINATOR)
                    + Math.mulDiv(minConsensusLayerGainPerBlockPPT * reportSize, baselineGrossCLBalance, _PPT_DENOMINATOR);

                if (newGrossCLBalance < lowerBound) {
                    return ("Consensus layer change below min gain or max loss", newGrossCLBalance, lowerBound);
                }
            }
            {
                // Upper bound on the rewards generated by validators scaled linearly with time and number of active
                // validators.
                uint256 upperBound = baselineGrossCLBalance
                    + Math.mulDiv(maxConsensusLayerGainPerBlockPPT * reportSize, baselineGrossCLBalance, _PPT_DENOMINATOR);

                if (newGrossCLBalance > upperBound) {
                    return ("Consensus layer change above max gain", newGrossCLBalance, upperBound);
                }
            }
        }

        return ("", 0, 0);
    }

    /// @dev Pushes a record to the list of records, emits an oracle added event, and processes the
    /// oracle record in the aggregator.
    /// @param record The record to push.
    function _pushRecord(OracleRecord memory record) internal {
        emit OracleRecordAdded(_records.length, record);
        _records.push(record);

        aggregator.processReturns({
            rewardAmount: record.windowWithdrawnRewardAmount,
            principalAmount: record.windowWithdrawnPrincipalAmount,
            shouldIncludeELRewards: true
        });
    }

    /// @notice Accepts the current pending update and adds it to the list of oracle records.
    /// @dev Accepting the current pending update resets the update pending state.
    function acceptPendingUpdate() external onlyRole(ORACLE_PENDING_UPDATE_RESOLVER_ROLE) {
        if (!hasPendingUpdate) {
            revert NoUpdatePending();
        }

        _pushRecord(_pendingUpdate);
        _resetPending();
    }

    /// @notice Rejects the current pending update.
    /// @dev Rejecting the current pending update resets the pending state.
    function rejectPendingUpdate() external onlyRole(ORACLE_PENDING_UPDATE_RESOLVER_ROLE) {
        if (!hasPendingUpdate) {
            revert NoUpdatePending();
        }

        emit OraclePendingUpdateRejected(_pendingUpdate);
        _resetPending();
    }

    /// @inheritdoc IOracleReadRecord
    function latestRecord() public view returns (OracleRecord memory) {
        return _records[_records.length - 1];
    }

    /// @inheritdoc IOracleReadPending
    function pendingUpdate() external view returns (OracleRecord memory) {
        if (!hasPendingUpdate) {
            revert NoUpdatePending();
        }
        return _pendingUpdate;
    }

    /// @inheritdoc IOracleReadRecord
    function recordAt(uint256 idx) external view returns (OracleRecord memory) {
        return _records[idx];
    }

    /// @inheritdoc IOracleReadRecord
    function numRecords() external view returns (uint256) {
        return _records.length;
    }

    /// @dev Resets the pending update by removing the update from storage and resetting the hasPendingUpdate flag.
    function _resetPending() internal {
        delete _pendingUpdate;
        hasPendingUpdate = false;
    }

    /// @notice Sets the finalization block number delta in the contract.
    /// See also {finalizationBlockNumberDelta}.
    /// @param finalizationBlockNumberDelta_ The new finalization block number delta.
    function setFinalizationBlockNumberDelta(uint256 finalizationBlockNumberDelta_)
        external
        onlyRole(ORACLE_MANAGER_ROLE)
    {
        if (
            finalizationBlockNumberDelta_ == 0
                || finalizationBlockNumberDelta_ > _FINALIZATION_BLOCK_NUMBER_DELTA_UPPER_BOUND
        ) {
            revert InvalidConfiguration();
        }

        finalizationBlockNumberDelta = finalizationBlockNumberDelta_;
        emit ProtocolConfigChanged(
            this.setFinalizationBlockNumberDelta.selector,
            "setFinalizationBlockNumberDelta(uint256)",
            abi.encode(finalizationBlockNumberDelta_)
        );
    }

    /// @inheritdoc IOracleManager
    /// @dev See also {oracleUpdater}.
    function setOracleUpdater(address newUpdater) external onlyRole(ORACLE_MANAGER_ROLE) notZeroAddress(newUpdater) {
        oracleUpdater = newUpdater;
        emit ProtocolConfigChanged(this.setOracleUpdater.selector, "setOracleUpdater(address)", abi.encode(newUpdater));
    }

    /// @notice Sets min deposit per validator in the contract.
    /// See also {minDepositPerValidator}.
    /// @param minDepositPerValidator_ The new min deposit per validator.
    function setMinDepositPerValidator(uint256 minDepositPerValidator_) external onlyRole(ORACLE_MANAGER_ROLE) {
        minDepositPerValidator = minDepositPerValidator_;
        emit ProtocolConfigChanged(
            this.setMinDepositPerValidator.selector,
            "setMinDepositPerValidator(uint256)",
            abi.encode(minDepositPerValidator_)
        );
    }

    /// @notice Sets max deposit per validator in the contract.
    /// See also {maxDepositPerValidator}.
    /// @param maxDepositPerValidator_ The new max deposit per validator.
    function setMaxDepositPerValidator(uint256 maxDepositPerValidator_) external onlyRole(ORACLE_MANAGER_ROLE) {
        maxDepositPerValidator = maxDepositPerValidator_;
        emit ProtocolConfigChanged(
            this.setMaxDepositPerValidator.selector,
            "setMaxDepositPerValidator(uint256)",
            abi.encode(maxDepositPerValidator)
        );
    }

    /// @notice Sets min consensus layer gain per block in the contract.
    /// See also {minConsensusLayerGainPerBlockPPT}.
    /// @param minConsensusLayerGainPerBlockPPT_ The new min consensus layer gain per block in parts per trillion.
    function setMinConsensusLayerGainPerBlockPPT(uint40 minConsensusLayerGainPerBlockPPT_)
        external
        onlyRole(ORACLE_MANAGER_ROLE)
        onlyFractionLeqOne(minConsensusLayerGainPerBlockPPT_, _PPT_DENOMINATOR)
    {
        minConsensusLayerGainPerBlockPPT = minConsensusLayerGainPerBlockPPT_;
        emit ProtocolConfigChanged(
            this.setMinConsensusLayerGainPerBlockPPT.selector,
            "setMinConsensusLayerGainPerBlockPPT(uint40)",
            abi.encode(minConsensusLayerGainPerBlockPPT_)
        );
    }

    /// @notice Sets max consensus layer gain per block in the contract.
    /// See also {maxConsensusLayerGainPerBlockPPT}.
    /// @param maxConsensusLayerGainPerBlockPPT_ The new max consensus layer gain per block in parts per million.
    function setMaxConsensusLayerGainPerBlockPPT(uint40 maxConsensusLayerGainPerBlockPPT_)
        external
        onlyRole(ORACLE_MANAGER_ROLE)
        onlyFractionLeqOne(maxConsensusLayerGainPerBlockPPT_, _PPT_DENOMINATOR)
    {
        maxConsensusLayerGainPerBlockPPT = maxConsensusLayerGainPerBlockPPT_;
        emit ProtocolConfigChanged(
            this.setMaxConsensusLayerGainPerBlockPPT.selector,
            "setMaxConsensusLayerGainPerBlockPPT(uint40)",
            abi.encode(maxConsensusLayerGainPerBlockPPT_)
        );
    }

    /// @notice Sets max consensus layer loss per block in the contract.
    /// See also {maxConsensusLayerLossPPM}.
    /// @param maxConsensusLayerLossPPM_ The new max consensus layer loss per block in parts per million.
    function setMaxConsensusLayerLossPPM(uint24 maxConsensusLayerLossPPM_)
        external
        onlyRole(ORACLE_MANAGER_ROLE)
        onlyFractionLeqOne(maxConsensusLayerLossPPM_, _PPM_DENOMINATOR)
    {
        maxConsensusLayerLossPPM = maxConsensusLayerLossPPM_;
        emit ProtocolConfigChanged(
            this.setMaxConsensusLayerLossPPM.selector,
            "setMaxConsensusLayerLossPPM(uint24)",
            abi.encode(maxConsensusLayerLossPPM_)
        );
    }

    /// @notice Sets the minimum report size.
    /// See also {minReportSizeBlocks}.
    /// @param minReportSizeBlocks_ The new minimum report size, in blocks.
    function setMinReportSizeBlocks(uint16 minReportSizeBlocks_) external onlyRole(ORACLE_MANAGER_ROLE) {
        // Sanity check on upper bound is covered by uint16 which is ~9 days.
        minReportSizeBlocks = minReportSizeBlocks_;
        emit ProtocolConfigChanged(
            this.setMinReportSizeBlocks.selector, "setMinReportSizeBlocks(uint16)", abi.encode(minReportSizeBlocks_)
        );
    }

    /// @notice Ensures that the given fraction is less than or equal to one.
    /// @param numerator The numerator of the fraction.
    /// @param denominator The denominator of the fraction.
    modifier onlyFractionLeqOne(uint256 numerator, uint256 denominator) {
        if (numerator > denominator) {
            revert InvalidConfiguration();
        }
        _;
    }

    /// @notice Ensures that the given address is not the zero address.
    /// @param addr The address to check.
    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
}
