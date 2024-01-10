// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract KururuLocker is Ownable {
	event Locked(uint256 indexed id, address indexed sender);
	event Unlocked(uint256 indexed id, address indexed sender);

	using SafeERC20 for IERC20;

	IERC20 public immutable kuru;
	address public receiver;
	uint256 public fee;

	constructor(IERC20 kuru_, uint256 fee_) {
		kuru = kuru_;
		fee = fee_;
		receiver = msg.sender;
	}

	function setFee(uint256 fee_) external onlyOwner {
		fee = fee_;
	}

	function setReceiver(address receiver_) external onlyOwner {
		require(receiver_ != address(0), "nope");
		receiver = receiver_;
	}

	function _transferFee() internal {
		if (fee == 0) {
			return;
		}
		kuru.transferFrom(msg.sender, receiver, fee);
	}

	struct Item {
		address owner;
		IERC20 token;
		uint256 amount;
		uint256 lockAt; // unix time (second)
		uint256 unlockAt; // unix time (seconds)
		bool unlocked;
	}
	mapping (uint256 => Item) public locker;
	uint256 public total;

	function lock(IERC20 token, uint256 amount, uint256 unlockAt) external returns (uint256) {
		require(amount > 0, "invalid amount");
		require(unlockAt > block.timestamp, "invalid unlock at");

		_transferFee();

		uint256 x = token.balanceOf(address(this));
		token.safeTransferFrom(msg.sender, address(this), amount);
		uint256 y = token.balanceOf(address(this));
		require(y == x + amount, "invalid");

		uint256 id = total;
		total++;
		locker[id] = Item(
			msg.sender,
			token,
			amount,
			block.timestamp,
			unlockAt,
			false
		);

		emit Locked(id, msg.sender);
		return id;
	}

	function unlock(uint256 id) external {
		Item storage it = locker[id];
		require(it.owner == msg.sender, "not own");
		require(!it.unlocked, "unlocked");
		require(block.timestamp > it.unlockAt, "locked");

		it.unlocked = true;
		it.token.safeTransfer(it.owner, it.amount);
		emit Unlocked(id, msg.sender);
	}
}
