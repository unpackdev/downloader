// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import "./EnumerableSet.sol";
import "./IGovernor.sol";
import "./ITimeLock.sol";

/// @title Governor
/// @notice Extends Uniswap's timelock contract with batch queueing/execution and reworked permissions model where,
///         instead of a single admin to perform all actions, there are multiple queue admins, a single veto admin,
///         and permissionless execution (which can optionally be restricted to non-contract accounts to prevent
///         unintended execution of governance proposals inside protocol functions)
contract Governor is IGovernor {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc IGovernor
    address public immutable override timeLock;

    /// @dev Set of queue admins
    EnumerableSet.AddressSet internal _queueAdminsSet;

    /// @inheritdoc IGovernor
    address public override vetoAdmin;

    /// @inheritdoc IGovernor
    bool public isExecutionByContractsAllowed;

    /// @inheritdoc IGovernor
    mapping(uint256 => BatchInfo) public override batchInfo;

    /// @inheritdoc IGovernor
    mapping(bytes32 => BatchedTxInfo) public override batchedTxInfo;

    /// @dev Ensures that function can only be called by the timelock contract
    modifier timeLockOnly() {
        if (msg.sender != timeLock) revert CallerNotTimelockException();
        _;
    }

    /// @dev Ensures that function can only be called by one of queue admins
    modifier queueAdminOnly() {
        if (!_queueAdminsSet.contains(msg.sender)) revert CallerNotQueueAdminException();
        _;
    }

    /// @dev Ensures that function can only be called by the veto admin
    modifier vetoAdminOnly() {
        if (msg.sender != vetoAdmin) revert CallerNotVetoAdminException();
        _;
    }

    /// @dev Ensures that function can't be called by contracts unless explicitly allowed
    modifier allowedCallerTypeOnly() {
        if (!isExecutionByContractsAllowed && msg.sender != tx.origin) revert CallerMustNotBeContractException();
        _;
    }

    /// @notice Constructs a new governor contract
    /// @param _timeLock Timelock contract address
    /// @param _queueAdmin Address to add as the first queue admin, can't be `address(0)`
    /// @param _vetoAdmin Address to set as the veto admin, can't be `address(0)`
    /// @param _allowExecutionByContracts Whether to allow transaction/batch execution by contracts
    constructor(address _timeLock, address _queueAdmin, address _vetoAdmin, bool _allowExecutionByContracts) {
        timeLock = _timeLock;
        _addQueueAdmin(_queueAdmin);
        _updateVetoAdmin(_vetoAdmin);

        if (_allowExecutionByContracts) {
            isExecutionByContractsAllowed = true;
            emit AllowExecutionByContracts();
        } else {
            emit ForbidExecutionByContracts();
        }
    }

    /// @inheritdoc IGovernor
    function queueAdmins() external view override returns (address[] memory) {
        return _queueAdminsSet.values();
    }

    // ------- //
    // ACTIONS //
    // ------- //

    /// @inheritdoc IGovernor
    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external override queueAdminOnly returns (bytes32 txHash) {
        txHash = _getTxHash(target, value, signature, data, eta);
        if (ITimeLock(timeLock).queuedTransactions(txHash)) revert TransactionAlreadyQueuedException();

        BatchInfo memory info = batchInfo[block.number];
        if (info.initiator != address(0)) {
            if (msg.sender != info.initiator) revert CallerNotBatchInitiatorException();
            if (eta != info.eta) revert ETAMistmatchException();

            batchedTxInfo[txHash] = BatchedTxInfo({batchBlock: uint64(block.number), index: info.length});
            batchInfo[block.number].length = info.length + 1;
        }

        ITimeLock(timeLock).queueTransaction(target, value, signature, data, eta);
    }

    /// @inheritdoc IGovernor
    function startBatch(uint80 eta) external override queueAdminOnly {
        if (batchInfo[block.number].initiator != address(0)) revert BatchAlreadyStartedException();
        batchInfo[block.number] = BatchInfo({initiator: msg.sender, length: 0, eta: eta});
        emit QueueBatch(msg.sender, block.number);
    }

    /// @inheritdoc IGovernor
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable override allowedCallerTypeOnly returns (bytes memory) {
        return _transactionAction(target, value, signature, data, eta, TxAction.Execute);
    }

    /// @inheritdoc IGovernor
    function executeBatch(TxParams[] calldata txs) external payable override allowedCallerTypeOnly {
        uint256 batchBlock = _batchAction(txs, TxAction.Execute);
        emit ExecuteBatch(msg.sender, batchBlock);
    }

    /// @inheritdoc IGovernor
    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external override vetoAdminOnly {
        _transactionAction(target, value, signature, data, eta, TxAction.Cancel);
    }

    /// @inheritdoc IGovernor
    function cancelBatch(TxParams[] calldata txs) external override vetoAdminOnly {
        uint256 batchBlock = _batchAction(txs, TxAction.Cancel);
        emit CancelBatch(msg.sender, batchBlock);
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @inheritdoc IGovernor
    function addQueueAdmin(address admin) external override timeLockOnly {
        _addQueueAdmin(admin);
    }

    /// @inheritdoc IGovernor
    function removeQueueAdmin(address admin) external override timeLockOnly {
        if (_queueAdminsSet.contains(admin)) {
            if (_queueAdminsSet.length() == 1) revert CantRemoveLastQueueAdminException();
            _queueAdminsSet.remove(admin);
            emit RemoveQueueAdmin(admin);
        }
    }

    /// @inheritdoc IGovernor
    function updateVetoAdmin(address admin) external override timeLockOnly {
        _updateVetoAdmin(admin);
    }

    /// @inheritdoc IGovernor
    function allowExecutionByContracts() external override timeLockOnly {
        if (!isExecutionByContractsAllowed) {
            isExecutionByContractsAllowed = true;
            emit AllowExecutionByContracts();
        }
    }

    /// @inheritdoc IGovernor
    function forbidExecutionByContracts() external override timeLockOnly {
        if (isExecutionByContractsAllowed) {
            isExecutionByContractsAllowed = false;
            emit ForbidExecutionByContracts();
        }
    }

    /// @inheritdoc IGovernor
    function claimTimeLockOwnership() external override queueAdminOnly {
        ITimeLock(timeLock).acceptAdmin();
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Executes or cancels a transaction, ensures that it is not part of any batch
    function _transactionAction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta,
        TxAction action
    ) internal returns (bytes memory result) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        if (batchedTxInfo[txHash].batchBlock != 0) revert CantPerformActionOutsideBatchException();
        return _performAction(target, value, signature, data, eta, action);
    }

    /// @dev Executes or cancels a batch of transactions, ensures that all transactions are processed in the correct order
    function _batchAction(TxParams[] calldata txs, TxAction action) internal returns (uint256 batchBlock) {
        uint256 len = txs.length;
        if (len == 0) revert IncorrectBatchException();

        batchBlock = batchedTxInfo[_getTxHash(txs[0])].batchBlock;
        if (batchBlock == 0) revert IncorrectBatchException();

        if (len != batchInfo[batchBlock].length) revert IncorrectBatchException();

        unchecked {
            for (uint256 i; i < len; ++i) {
                TxParams calldata tx_ = txs[i];
                bytes32 txHash = _getTxHash(tx_);

                BatchedTxInfo memory info = batchedTxInfo[txHash];
                if (info.batchBlock != batchBlock || info.index != i) revert UnexpectedTransactionException(txHash);

                _performAction(tx_.target, tx_.value, tx_.signature, tx_.data, tx_.eta, action);
                delete batchedTxInfo[txHash];
            }
        }

        delete batchInfo[batchBlock];
    }

    /// @dev Executes or cancels a transaction
    function _performAction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta,
        TxAction action
    ) internal returns (bytes memory result) {
        if (action == TxAction.Execute) {
            result = ITimeLock(timeLock).executeTransaction{value: value}(target, value, signature, data, eta);
        } else {
            ITimeLock(timeLock).cancelTransaction(target, value, signature, data, eta);
        }
    }

    /// @dev `addQueueAdmin` implementation
    function _addQueueAdmin(address admin) internal {
        if (admin == address(0)) revert AdminCantBeZeroAddressException();
        if (!_queueAdminsSet.contains(admin)) {
            _queueAdminsSet.add(admin);
            emit AddQueueAdmin(admin);
        }
    }

    /// @dev `updateVetoAdmin` implementation
    function _updateVetoAdmin(address admin) internal {
        if (admin == address(0)) revert AdminCantBeZeroAddressException();
        if (vetoAdmin != admin) {
            vetoAdmin = admin;
            emit UpdateVetoAdmin(admin);
        }
    }

    /// @dev Computes transaction hash
    function _getTxHash(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(target, value, signature, data, eta));
    }

    /// @dev Computes transaction hash
    function _getTxHash(TxParams calldata tx_) internal pure returns (bytes32) {
        return _getTxHash(tx_.target, tx_.value, tx_.signature, tx_.data, tx_.eta);
    }
}
