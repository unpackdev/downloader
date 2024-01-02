// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 amount) external returns (bool);
}

contract MultiSigWallet {
	event Deposit(address indexed sender, uint256 value, uint256 balance);
	event SubmitTransaction(
		address indexed owner,
		uint256 indexed txIndex,
		address indexed to,
		uint256 value,
		bytes data
	);
	event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
	event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
	event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
	event CancelTransaction(address indexed owner, uint256 indexed txIndex);

	struct Transaction {
		address to;
		uint256 value;
		bytes data;
		bool executed;
	}

	address[] public owners;
	address public admin_backup;
	uint256 public numConfirmationsRequired;
	uint256 public unexecutedTxCount;
	uint256 public transactionCount;

	mapping(uint256 => Transaction) public transactions;
	mapping(uint256 => mapping(address => bool)) public confirmations;
	mapping(address => bool) public isOwner;

	modifier onlyOwner() {
		require(
			isOwner[msg.sender] || msg.sender == admin_backup,
			"only allowed owners or admin backup"
		);
		_;
	}
	modifier onlyAdminBackup() {
		require(msg.sender == admin_backup, "only allowed for admin backup");
		_;
	}
	modifier txExists(uint256 _txIndex) {
		require(_txIndex < transactionCount, "tx does not exist");
		_;
	}
	modifier notExecuted(uint256 _txIndex) {
		require(!transactions[_txIndex].executed, "tx already executed");
		_;
	}
	modifier Confirmed(uint256 _txIndex, address owner) {
		require(confirmations[_txIndex][owner], "tx not confirmed");
		_;
	}
	modifier notConfirmed(uint256 _txIndex, address owner) {
		require(!confirmations[_txIndex][owner], "tx already confirmed");
		_;
	}

	constructor(
		uint256 _numConfirmationsRequired,
		address _admin_backup,
		address[] memory _owners
	) {
		require(_owners.length > 0, "owners required");
		require(
			_numConfirmationsRequired > 1 &&
			_numConfirmationsRequired <= _owners.length + 1,
			"invalid number of required confirmations"
		);

		require(_admin_backup != address(0), "invalid admin_backup address");
		admin_backup = _admin_backup;

		for (uint256 i = 0; i < _owners.length; i++) {
			address owner = _owners[i];
			require(owner != address(0), "invalid owner");
			require(!isOwner[owner], "not unique owner");
			isOwner[owner] = true;
			owners.push(owner);
		}

		require(!isOwner[msg.sender], "not unique owner");
		isOwner[msg.sender] = true;
		owners.push(msg.sender);


		unexecutedTxCount = 0;
		numConfirmationsRequired = _numConfirmationsRequired;
	}

	receive() external payable {
		emit Deposit(msg.sender, msg.value, address(this).balance);
	}

	function submitMultiTransaction(address[] memory receivers, uint256[] memory amounts)
	public onlyOwner
	{
		require(
			receivers.length == amounts.length,
			"input array length is not matching"
		);

		for (uint256 j = 0; j < receivers.length; j++) {
			// check eth balance.
			require(
				address(this).balance + getUnexecutedEthBalance() >= amounts[j],
				"insufficient ETH balance."
			);

			address payable receiver = payable(receivers[j]);
			uint256 txIndex = transactionCount;
			transactions[txIndex] = Transaction({
				to: receiver,
				value: amounts[j],
				data: "0x0",
				executed: false
			});
			transactionCount++;
			unexecutedTxCount++;
			emit SubmitTransaction(
				msg.sender,
				txIndex,
				receiver,
				amounts[j],
				"0x0"
			);

			confirmTransaction(txIndex);
		}
	}

	function submitErc20MultiTransaction(address tokenAddress, bytes[] memory methodData)
	public onlyOwner
	{
		for (uint256 j = 0; j < methodData.length; j++) {
			uint256 txIndex = transactionCount;
			transactions[txIndex] = Transaction({
				to: tokenAddress,
				value: 0,
				data: methodData[j],
				executed: false
			});
			transactionCount++;
			unexecutedTxCount++;
			emit SubmitTransaction(
				msg.sender,
				txIndex,
				tokenAddress,
				0,
				methodData[j]
			);

			confirmTransaction(txIndex);
		}
	}

	function confirmAllTransaction()
	public onlyOwner
	{
		for (uint256 i = 0; i < transactionCount; i++) {
			if (transactions[i].executed == false) {
				confirmTransaction(i);
			}
		}
	}

	function confirmTransaction(uint256 _txIndex)
	public onlyOwner txExists(_txIndex) notConfirmed(_txIndex, msg.sender)
	{
		confirmations[_txIndex][msg.sender] = true;
		emit ConfirmTransaction(msg.sender, _txIndex);

		executeTransaction(_txIndex);
	}

	function executeTransaction(uint256 _txIndex)
	public onlyOwner notExecuted(_txIndex)
	{
		if (isConfirmedAll(_txIndex)) {
			Transaction storage transaction = transactions[_txIndex];
			(bool success,) = transaction.to.call{value: transaction.value}(
				transaction.data
			);
			require(success, "submitted transaction execution failed");
			transaction.executed = true;
			unexecutedTxCount--;
			emit ExecuteTransaction(msg.sender, _txIndex);
		}
	}

	function revokeConfirmation(uint256 _txIndex)
	public onlyOwner txExists(_txIndex) notExecuted(_txIndex) Confirmed(_txIndex, msg.sender)
	{
		confirmations[_txIndex][msg.sender] = false;
		emit RevokeConfirmation(msg.sender, _txIndex);
	}

	function cancelSubmitTransaction(uint256 _txIndex)
	public onlyOwner txExists(_txIndex) notExecuted(_txIndex)
	{
		transactions[_txIndex].executed = true;
		unexecutedTxCount--;
		emit CancelTransaction(msg.sender, _txIndex);
	}

	function cancelAllTransactions()
	public onlyOwner
	{
		for (uint256 i = 0; i < transactionCount; i++) {
			if (!transactions[i].executed) {
				cancelSubmitTransaction(i);
			}
		}
	}

	function transferERC20(address erc20_token, address to, uint256 amount)
	public onlyAdminBackup
	returns (bool)
	{
		ERC20 token = ERC20(erc20_token);

		require(
			token.balanceOf(address(this)) >= amount,
			"Insufficient token balance in the contract"
		);

		return token.transfer(to, amount);
	}

	function transferETH(address payable to, uint256 amount)
	public onlyAdminBackup
	returns (bool)
	{
		require(
			address(this).balance >= amount,
			"Insufficient ETH balance in the contract"
		);

		(bool success,) = to.call{value: amount}("");
		require(success, "Transfer failed");

		return true;
	}

	function isConfirmedAll(uint256 _txIndex)
	public view
	returns (bool)
	{
		uint256 count = 0;
		for (uint256 i = 0; i < owners.length; i++) {
			if (confirmations[_txIndex][owners[i]]) count += 1;
			if (count == numConfirmationsRequired) return true;
		}
		return false;
	}

	function getUnexecutedTransactions()
	public view
	returns (uint[] memory)
	{
		uint[] memory unexecutedTxList = new uint[](
			unexecutedTxCount
		);
		uint256 j = 0;
		for (uint256 i = 0; i < transactionCount; i++) {
			if (!transactions[i].executed) {
				unexecutedTxList[j] = i;
				j++;
			}
		}
		return unexecutedTxList;
	}

	function getUnexecutedEthBalance()
	public view
	returns (uint256)
	{
		uint256 unexecutedBalance = 0;
		for (uint256 i = 0; i < transactionCount; i++) {
			if (!transactions[i].executed && transactions[i].value > 0) {
				unexecutedBalance += transactions[i].value;
			}
		}
		return unexecutedBalance;
	}

	function getOwners()
	public view
	returns (address[] memory)
	{
		return owners;
	}
}