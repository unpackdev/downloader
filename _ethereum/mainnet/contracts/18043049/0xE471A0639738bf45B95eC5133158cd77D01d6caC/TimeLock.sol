// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLock
 * @dev A smart contract for managing time-locked transactions.
 */
contract TimeLock {
    address public multisigAddress; // Address of the multisignature wallet
    uint256 public unlockTime; // Duration of the lock in seconds
    uint256 public nextTxId; // ID for the next transaction

    struct LockedTransaction {
        uint256 unlockTime; // Timestamp when the transaction can be executed
        bool executed; // Indicates if the transaction has been executed
        address to; // Recipient address of the transaction
        bytes data; // Data payload of the transaction
    }

    mapping(uint256 => LockedTransaction) public lockedTransactions; // Stores locked transactions

    modifier onlyMultisig() {
        require(msg.sender == multisigAddress, "Only the multisig contract can call this function");
        _;
    }

    event TransactionSubmitted(uint256 indexed txId, address indexed to, bytes data, uint256 unlockTime);
    event TransactionExecuted(uint256 indexed txId, address indexed to, bytes data);

    /**
     * @dev Constructor to initialize the TimeLock contract.
     * @param _multisigAddress Address of the multisignature wallet.
     * @param _unlockTime Duration of the lock in seconds.
     */
    constructor(address _multisigAddress, uint256 _unlockTime) {
        multisigAddress = _multisigAddress;
        unlockTime = _unlockTime;
        nextTxId = 1;
    }

    /**
     * @dev Submits a transaction to be executed after the specified unlock time.
     * @param _to Recipient address of the transaction.
     * @param _data Data payload of the transaction.
     */
    function submitTransaction(address _to, bytes memory _data) public onlyMultisig {
        require(nextTxId == 1 || lockedTransactions[nextTxId - 1].executed, "Previous transaction not executed yet");

        uint256 newUnlockTime = block.timestamp + unlockTime;
        lockedTransactions[nextTxId] = LockedTransaction(newUnlockTime, false, _to, _data);
        emit TransactionSubmitted(nextTxId, _to, _data, newUnlockTime);
        nextTxId++;
    }

    /**
     * @dev Executes a transaction if the unlock time has passed.
     */
    function executeTransaction() public {
        require(nextTxId > 1, "No transactions to execute");

        uint256 currentTxId = nextTxId - 1;
        LockedTransaction storage transaction = lockedTransactions[currentTxId];

        require(block.timestamp >= transaction.unlockTime, "Transaction is locked until unlock time");
        require(!transaction.executed, "Transaction already executed");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: 0}(transaction.data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(currentTxId, transaction.to, transaction.data);
    }
}
