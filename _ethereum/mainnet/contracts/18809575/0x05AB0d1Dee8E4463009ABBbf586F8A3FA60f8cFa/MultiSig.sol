// SPDX-License-Identifier: MIT
// https://docs.metroxynth.io/
pragma solidity ^0.8.16;

contract MultiSig {
    address[] private _owners;
    uint256 private _requiredConfirmations;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    uint256 public transactionCount;

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Not an owner");
        _;
    }

    constructor(address[] memory owners, uint256 requiredConfirmations) {
        require(owners.length > 0, "Owners required");
        require(
            requiredConfirmations > 0 && requiredConfirmations <= owners.length,
            "Invalid number of required confirmations"
        );

        _owners = owners;
        _requiredConfirmations = requiredConfirmations;
    }

    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (uint256) {
        uint256 transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        return transactionId;
    }

    function confirmTransaction(uint256 transactionId) public onlyOwner {
        require(
            !confirmations[transactionId][msg.sender],
            "Transaction already confirmed by this owner"
        );
        require(!transactions[transactionId].executed, "Transaction already executed");

        confirmations[transactionId][msg.sender] = true;

        executeTransaction(transactionId);
    }

    function executeTransaction(uint256 transactionId) public onlyOwner {
        require(!transactions[transactionId].executed, "Transaction already executed");

        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
            require(success, "Transaction failed");
        }
    }

    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool)
    {
        uint256 confirmedCount = 0;
        for (uint256 i = 0; i < _owners.length; i++) {
            if (confirmations[transactionId][_owners[i]]) {
                confirmedCount += 1;
            }
            if (confirmedCount >= _requiredConfirmations) {
                return true;
            }
        }
        return false;
    }
}