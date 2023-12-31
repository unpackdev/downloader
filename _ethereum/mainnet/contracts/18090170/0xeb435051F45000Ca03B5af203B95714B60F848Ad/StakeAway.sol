// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";


contract StakeAway is Ownable, Pausable
{
	address payable private managerAddress;
	uint256 private fixedFeeAmount;

	event Claimed(address indexed tokenContractAddress, address indexed claimerAddress);
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
		require(msg.value == fixedFeeAmount, "Incorrect fee amount");

		(bool successFee,) = managerAddress.call{value: fixedFeeAmount}("");
		require(successFee, "Fee payment failed");

		emit Claimed(tokenContractAddress, msg.sender);
	}

}

