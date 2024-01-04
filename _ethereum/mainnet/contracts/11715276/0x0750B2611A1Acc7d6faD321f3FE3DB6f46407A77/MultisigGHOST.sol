// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Address.sol";

contract MultiSigWallet {
	event Deposit(address indexed sender, uint amount, uint balance);
	event SubmitTransaction(
		address indexed owner,
		uint indexed txIndex,
		address indexed to,
		uint value,
		bytes data
	);
	event ConfirmTransaction(address indexed owner, uint indexed txIndex);
	event RevokeConfirmation(address indexed owner, uint indexed txIndex);
	event ExecuteTransaction(address indexed owner, uint indexed txIndex);
	
	address[] private owners;
	mapping(address => bool) private isOwner;
	uint private numConfirmationsRequired;
	
	struct Transaction {
		address to;
		uint value;
		bytes data;
		bool executed;
		uint numConfirmations;
	}
	
	// mapping from tx index => owner => bool
	mapping(uint => mapping(address => bool)) public isConfirmed;
	
	Transaction[] public transactions;
	

	/**
	 * @dev Throws if sender is not one of the owners.
	 */
	modifier onlyOwner() {
		require(isOwner[msg.sender], "not owner");
		_;
	}
	

	/**
	 * @dev Throws if txIndex exists in transactions array.
	 * @param _txIndex Transaction index.
	 */
	modifier txExists(uint _txIndex) {
		require(_txIndex < transactions.length, "tx does not exist");
		_;
	}
	

	/**
	 * @dev Throws if field `executed` equal to `true`.
	 * @param _txIndex Transaction index.
	 */
	modifier notExecuted(uint _txIndex) {
		require(!transactions[_txIndex].executed, "tx already executed");
		_;
	}
	

	/**
	 * @dev Throws if transaction not confirmed by sender.
	 * @param _txIndex Transaction index.
	 */
	modifier notConfirmed(uint _txIndex) {
		require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
		_;
	}
	
	
	/**
	 * @dev Constructor for MultiSigWallet.
	 * Required: array of owners to be not empty.
	 * Required: confirmations to be between 1 and length of owners array.
	 * Required: every owner not to be zero-address.
	 * Required: every onwer not to be smart-contract???
	 * Required: no duplicates in owner array.
	 * 
	 * @param _owners Array of owners addresses.
	 * @param _numConfirmationsRequired Minimal number of confirmations needed to pass transaction.
	 */
	constructor(address[] memory _owners, uint _numConfirmationsRequired) {
		require(_owners.length > 0, "owners required");
		require(_numConfirmationsRequired > 0, "invalid number of required confirmations, less zero");
		require(_numConfirmationsRequired <= _owners.length, "invalid number of required confirmations, more than owners");
		
		for (uint i = 0; i < _owners.length; i++) {
			address owner = _owners[i];
			
			require(owner != address(0), "invalid owner");
			require(!isOwner[owner], "owner not unique");
			require(!Address.isContract(owner), "owner is smart contract");
			
			isOwner[owner] = true;
			owners.push(owner);
		}
		
		numConfirmationsRequired = _numConfirmationsRequired;
	}
	
	
	/**
	 * @dev Fallback function that will take ether and log event.
	 */
	receive() payable external {
		emit Deposit(msg.sender, msg.value, address(this).balance);
	}
	
	
	/**
	 * @dev Offers withdrawal transaction.
	 *
	 * @param _to Address where to withdraw funds.
	 * @param _value Amount of wei to withdraw.
	 * @param _data Complete calldata. 
	 */
	function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
		require(!Address.isContract(_to), "cannot withdraw to smart contract");
		require(_to != address(0), "canot withdraw to zero-address");
		require(_value > 0.3 ether, "cannot withdraw less 0.3 ETH");
		
		uint txIndex = transactions.length;
		transactions.push(Transaction({
			to: _to,
			value: _value,
			data: _data,
			executed: false,
			numConfirmations: 0
		}));
		
		emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
	}
	
	
	/**
	 * @dev Confirm proposed withdrawal transaction.
	 * Only address from owners array can use this function.
	 * Transaction should exist.
	 * Transaction should not be executed before.
	 * Transaction should not be confirmed by sender address.
	 * 
	 * @param _txIndex Transaction index.
	 */
	function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		transaction.numConfirmations += 1;
		isConfirmed[_txIndex][msg.sender] = true;
		
		emit ConfirmTransaction(msg.sender, _txIndex);
	}
	
	
	/**
	 * @dev Execute transaction that previously was confirmed by
	 * majority of owners (>= numConfirmationsRequired)
	 *
	 * Only address from owners array can execute it.
	 * Transaction should exist.
	 * Transaction should not be executed before.
	 *
	 * @param _txIndex Transaction index
	 */
	function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
		
		transaction.executed = true;
		
		(bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
		require(success, "tx failed");
		
		emit ExecuteTransaction(msg.sender, _txIndex);
	}
	
	
	/**
	 * @dev Revoke vote for withdrawal transaction.
	 *
	 * Only address from the owners array.
	 * Transaction should exists.
	 * Transaction should not be executed before.
	 * Transaction should be confirmed by this address before.
	 * 
	 * @param _txIndex Transaction index.
	 */
	function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
		Transaction storage transaction = transactions[_txIndex];
		
		require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
		
		transaction.numConfirmations -= 1;
		isConfirmed[_txIndex][msg.sender] = false;
		
		emit RevokeConfirmation(msg.sender, _txIndex);
	}
	
	
	/**
	 * @return Array of owners.
	 */
	function getOwners() public view returns (address[] memory) {
		return owners;
	}
	
	
	/**
	 * @return Number of minimum confirmations required
	 */
	function getConfirmationsCount() public view returns (uint) {
		return numConfirmationsRequired;
	}
	
	
	/**
	 * @return Total amount of transactions.
	 */
	function getTransactionCount() public view returns (uint) {
		return transactions.length;
	}
	
	
	/**
	 * @dev Get transaction full information.
	 * @param _txIndex Transaction index.
	 */
	function getTransaction(uint _txIndex) public view txExists(_txIndex) returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
		Transaction storage transaction = transactions[_txIndex];
		
		return (
			transaction.to,
			transaction.value,
			transaction.data,
			transaction.executed,
			transaction.numConfirmations
		);
	}
	
	
	/**
	 * @return Balance of current smart contract.
	 */
	function balance() public view returns (uint256) {
		return address(this).balance;
	}
	
	
	/**
	 * @dev Funciton that will clean up wallet balance.
	 * Only main owner can call.
	 * Balance should be less 0.3 ETH (otherwise call submitTransaction).
	 * Address to withdraw not zero-address.
	 * Address to withdraw not smart contract.
	 * 
	 * @param _to Address where all funds of smart-contract should go.
	 */
	function destructor(address payable _to) public {
		require(msg.sender == owners[0], "not the master");
		require(address(this).balance <= 0.3 ether, "too much balance");
		require(address(this).balance > 0, "not due payment");
		require(_to != address(0), "cannot be zero-address");
		require(!Address.isContract(_to), "cannot be smart contract");
		
		selfdestruct(_to);
	}

}
