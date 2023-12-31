// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract MintEnginePaymentContract is UUPSUpgradeable, OwnableUpgradeable {
    struct Transaction {
        uint256 id;
        uint256 paymentAmount;
        uint256 paymentDate;
        address paymentWallet;
        uint256 mintEngineAccountId;
    }

    address private vaultAddress;

    Transaction[] private transactions;

    event PaymentWithdrawal(address indexed user, uint256 amount);

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        vaultAddress = msg.sender;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pay(uint256 id, uint256 mintEngineAccountId) public payable {
        require(msg.value > 0, "Payment amount must be greater than 0");
        require(id != 0, "Transaction Id required");
        require(mintEngineAccountId != 0, "Account Id required");

        require(!transactionExists(id), "Transaction with the same ID already exists");

        Transaction memory newTransaction = Transaction({
            id: id,
            paymentAmount: msg.value,
            paymentDate: block.timestamp,
            paymentWallet: msg.sender,
            mintEngineAccountId: mintEngineAccountId
        });

        transactions.push(newTransaction);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        bool success;

        (success, ) = vaultAddress.call{value: balance}("");
        if (!success) {
            (success, ) = msg.sender.call{value: balance}("");
            require(success, "Transfer to owner failed");
        }

        require(success, "Transfer failed");
        emit PaymentWithdrawal(msg.sender, balance);
    }


    function getTransaction(uint256 id) public view returns (Transaction memory) {
        require(id != 0, "Transaction Id required");
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id == id) {
                return transactions[i];
            }
        }
        revert("Transaction not found");
    }

    function getTransactionsByWallet() public view returns (Transaction[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].paymentWallet == msg.sender) {
                count++;
            }
        }
        Transaction[] memory result = new Transaction[](count);
        count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].paymentWallet == msg.sender) {
                result[count] = transactions[i];
                count++;
            }
        }
        return result;
    }

    function getTransactionsByAccountId(uint256 mintEngineAccountId) public view returns (Transaction[] memory) {
        require(mintEngineAccountId != 0, "Account Id required");
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].mintEngineAccountId == mintEngineAccountId) {
                count++;
            }
        }
        Transaction[] memory result = new Transaction[](count);
        count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].mintEngineAccountId == mintEngineAccountId) {
                result[count] = transactions[i];
                count++;
            }
        }
        return result;
    }

    function addTransaction(
        uint256 id,
        uint256 paymentAmount,
        address paymentWallet,
        uint256 mintEngineAccountId
    ) public onlyOwner {
        require(id != 0, "Transaction Id required");
        require(paymentAmount > 0, "Payment amount must be greater than zero");
        require(paymentWallet != address(0), "Payment wallet cannot be the zero address");
        require(mintEngineAccountId != 0, "Account Id required");
        require(!transactionExists(id), "Transaction with the same ID already exists");

        Transaction memory newTransaction = Transaction({
            id: id,
            paymentAmount: paymentAmount,
            paymentDate: block.timestamp,
            paymentWallet: paymentWallet,
            mintEngineAccountId: mintEngineAccountId
        });
        transactions.push(newTransaction);
    }

    function removeTransaction(uint256 id) public onlyOwner {
        require(id != 0, "Transaction Id required");

        uint256 indexToRemove = findTransactionIndex(id);

        require(indexToRemove != transactions.length, "Transaction not found");

        for (uint256 i = indexToRemove; i < transactions.length - 1; i++) {
            transactions[i] = transactions[i + 1];
        }
        transactions.pop();
    }

    function setVaultAddress(address a) public onlyOwner {
        require(a != address(0), "Invalid address");
        vaultAddress = a;
    }

    function getVaultAddress() public view returns (address) {
        return vaultAddress;
    }

    function transactionExists(uint256 id) internal view returns (bool) {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id == id) {
                return true;
            }
        }
        return false;
    }

    function findTransactionIndex(uint256 id) internal view returns (uint256) {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id == id) {
                return i;
            }
        }
        return transactions.length;
    }

    function getNextTransactionId() public view returns (uint256) {
        uint256 highestId = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i].id > highestId) {
                highestId = transactions[i].id;
            }
        }
        return highestId + 1;
    }

}
