// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IStaking.sol";

contract Splitter is Ownable {
	using SafeERC20 for IERC20;

	IERC20 public immutable TOKEN;
	address[] public receivers;
	mapping(address => uint) public receiverToShare;
	uint internal constant PRECISION = 10000;

	constructor(IERC20 _token) {
		TOKEN = _token;
	}

	function split() external {
		address[] memory receiversCached = receivers;
		uint length = receiversCached.length;

		require(length != 0, "not setup yet");

		uint initialBalance = TOKEN.balanceOf(address(this));

		// mutlisig first - no distribute call
		uint amountReceiver = initialBalance * receiverToShare[receiversCached[0]] / PRECISION;
		if (amountReceiver > 0) TOKEN.safeTransfer(receiversCached[0], amountReceiver);

		for (uint i = 1; i < length; ++i) {
			address receiver = receiversCached[i];
			amountReceiver = initialBalance * receiverToShare[receiver] / PRECISION;
			if (amountReceiver > 0) {
				TOKEN.safeTransfer(receiver, amountReceiver);
				IStaking(receiver).distribute(amountReceiver); // revert if no implementation
			}
		}
	}

	function setReceiversAndShares(address[] calldata _receivers, uint[] calldata _shares) external onlyOwner {
		require(_receivers.length == _shares.length, "length discrepency");
		
		address[] memory receiversCached = receivers;
		for (uint i; i < receiversCached.length; ++i) {
			receiverToShare[receiversCached[i]] = 0;
		}

		uint sumShares;
		for (uint i; i < _receivers.length; ++i) {
			receiverToShare[_receivers[i]] = _shares[i];
			sumShares += _shares[i];
		}
		require(sumShares == PRECISION, "sum discrepency");

		receivers = _receivers;
	}

	function pendingOf(address who) external view returns (uint) {
		uint initialBalance = TOKEN.balanceOf(address(this));
		return initialBalance * receiverToShare[who] / PRECISION;
	}
}
