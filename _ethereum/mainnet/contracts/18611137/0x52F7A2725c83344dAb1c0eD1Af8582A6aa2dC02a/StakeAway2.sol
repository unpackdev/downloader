// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";


contract StakeAway2 is Ownable, Pausable
{
	address payable private managerAddress;
	uint256 private fixedFeeAmount;

	// Allow fee amount to be overridden on a contract-by-contract basis.

	mapping(address => uint256) private contractFees;

	event Claimed(address indexed tokenContractAddress, address indexed claimerAddress, uint256 indexed feeAmount);
	event PaymentSent(address indexed senderAddress, address indexed receiverAddress, uint256 amount);

	constructor(address payable managerAddress_, uint256 fixedFeeAmount_)
	{
		managerAddress = managerAddress_;
		fixedFeeAmount = fixedFeeAmount_;
	}

	function setManagerAddress(address payable managerAddress_) external onlyOwner
	{
		require(managerAddress_ != address(0), "Address missing");

		managerAddress = managerAddress_;
	}

	function getManagerAddress() external view returns (address)
	{
		return managerAddress;
	}

	// fixedFeeAmount is in Wei
	function setFixedFeeAmount(uint256 fixedFeeAmount_) external onlyOwner
	{
		fixedFeeAmount = fixedFeeAmount_;
	}

	function getFixedFeeAmount() external view returns (uint256)
	{
		return fixedFeeAmount;
	}

	// Amounts are in Wei.

	function setContractFeeAmount(address contractAddress_, uint256 feeAmount_) external onlyOwner
	{
		require(contractAddress_ != address(0), "Invalid contract");
		require(feeAmount_ > 0, "Invalid fee amount");

		contractFees[contractAddress_] = feeAmount_;
	}

	function clearContractFeeAmount(address contractAddress_) external onlyOwner
	{
		uint256 feeAmount = contractFees[contractAddress_];
		require(feeAmount > 0, "Invalid contract");

		delete contractFees[contractAddress_];
	}

	function getContractFeeAmount(address contractAddress_) external view returns (uint256)
	{
		return contractFees[contractAddress_];
	}

	function sendPayment(address payable receiverAddress) external payable onlyOwner
	{
		require(receiverAddress != address(0), "Address missing");
		require(msg.value > 0, "Invalid amount");

		(bool successFee,) = receiverAddress.call{value: msg.value}("");
		require(successFee, "Payment failed");

		emit PaymentSent(msg.sender, receiverAddress, msg.value);
	}

	function claim(address tokenContractAddress) external payable whenNotPaused
	{
		uint256 feeAmount = contractFees[tokenContractAddress];
		if (feeAmount == 0) {
			feeAmount = fixedFeeAmount;
		}
		require(msg.value == feeAmount, "Incorrect fee amount");

		(bool successFee,) = managerAddress.call{value: feeAmount}("");
		require(successFee, "Fee payment failed");

		emit Claimed(tokenContractAddress, msg.sender, feeAmount);
	}

}

