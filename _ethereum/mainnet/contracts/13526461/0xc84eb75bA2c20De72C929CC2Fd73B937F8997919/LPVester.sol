// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeMath.sol";

contract LPVester {
	using SafeMath for uint256;

	address public erpLP;
	address public recipient;

	uint256 public vestingAmount;
	uint256 public vestingBegin;
	uint256 public vestingCliff;
	uint256 public vestingEnd;

	uint256 public lastUpdate;

	constructor(
		address erpLP_,
		address recipient_,
		uint256 vestingAmount_,
		uint256 vestingBegin_,
		uint256 vestingCliff_,
		uint256 vestingEnd_
	) {
		require(erpLP_ != address(0), "TreasuryVester::constructor: erpLP token zero address");
		require(recipient_ != address(0), "TreasuryVester::constructor: recipient zero address");
		require(vestingBegin_ >= block.timestamp, "TreasuryVester::constructor: vesting begin too early");
		require(vestingCliff_ >= vestingBegin_, "TreasuryVester::constructor: cliff is too early");
		require(vestingEnd_ > vestingCliff_, "TreasuryVester::constructor: end is too early");

		erpLP = erpLP_;
		recipient = recipient_;

		vestingAmount = vestingAmount_;
		vestingBegin = vestingBegin_;
		vestingCliff = vestingCliff_;
		vestingEnd = vestingEnd_;

		lastUpdate = vestingBegin;
	}

	function setRecipient(address recipient_) public {
		require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
		recipient = recipient_;
	}

	function claim() public {
		require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
		uint256 amount;
		if (block.timestamp >= vestingEnd) {
			amount = IERC20(erpLP).balanceOf(address(this));
		} else {
			amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
			lastUpdate = block.timestamp;
		}
		IERC20(erpLP).transfer(recipient, amount);
	}
}
