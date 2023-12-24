// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IStaking.sol";

contract Staker is Ownable, ReentrancyGuard {
	IERC20 public constant token = IERC20(0x2F09757B222642C649f1f9d80798b0123fA18Ba9);
	IStaking public constant staking = IStaking(0x9e66174D98EDCcea014E1eBafCA223d889a360be);

	address[] public receivers;
	mapping(address => uint) public receiverToPercentage;
	uint private constant PRECISION = 10000;

	receive() external payable {}

	// anyone willing to pay gas fees
	function claimAndDistribute() external nonReentrant {
		address[] memory receiversCached = receivers;
		uint length = receiversCached.length;

		// claim would revert if fully unstake and logic updated
		try staking.claim() {} catch {}

		uint startBalance = address(this).balance;
		for (uint i; i < length; ++i) {
			uint amount = startBalance * receiverToPercentage[receiversCached[i]] / PRECISION;
			if (amount > 0) Address.sendValue(payable(receiversCached[i]), amount);
		}
	}

	function pending(address who) external view returns (uint) {
		uint total = address(this).balance;
		total += staking.pending(address(this));
		return total * receiverToPercentage[who] / PRECISION;
	}

	// stake additional tokens
	function stake() external onlyOwner {
		uint balance = token.balanceOf(address(this));
		token.transfer(address(staking), balance);
	}

	// if logic update
	function withdraw() external onlyOwner {
		staking.withdraw();
	}

	// if logic update
	function recoveryERC20(IERC20 erc20) external onlyOwner {
		uint balance = erc20.balanceOf(address(this));
		erc20.transfer(owner(), balance);
	}

	// likely unecessary but better be safe than sorry
	function recoveryETH() external onlyOwner {
		uint balance = address(this).balance;
		Address.sendValue(payable(owner()), balance);
	}

	// update receivers
	function setReceiversAndPercentages(address[] calldata receivers_, uint[] calldata percentages_) external onlyOwner {
		require(receivers_.length > 0 && receivers_.length <= 20, "loop size");
		
		address[] memory receiversCached = receivers;
		uint length = receiversCached.length;
		for (uint i; i < length; ++i) receiverToPercentage[receiversCached[i]] = 0;

		uint sum;
		for (uint i; i < receivers_.length; ++i) {
			receiverToPercentage[receivers_[i]] = percentages_[i];
			sum += percentages_[i];
		}
		require(sum == PRECISION, "sum");

		receivers = receivers_;
	}
}
