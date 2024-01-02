// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ISplitter.sol";

contract Staking is Ownable {
	using SafeERC20 for IERC20;

	struct User {
		uint stakedAmount;
		uint shares;
		uint lockStartTime;
		uint lockEndTime;
		uint sumGPUS;
	}

	IERC20 public immutable TOKEN;
	ISplitter public immutable SPLITTER;

	mapping(address => User) public users;
	uint public totalDistributed;
	uint public totalStaked;
	uint public totalShares;
	uint public sumGPUS;
	uint public lastRoundingError;
	uint public maxLockDuration;
	uint public maxLockBonus; // 1 ether == 100%
	uint internal constant PRECISION = 1 ether;

	event SetMaxLock(uint _maxLockDuration, uint _maxLockBonus);

	constructor(IERC20 _token, ISplitter _splitter) {
		TOKEN = _token;
		SPLITTER = _splitter;
	}

	function stake(uint _amount, uint _lockDuration) external {
		require(_amount > 0, "amount cannot be zero");
		require(_lockDuration <= maxLockDuration, "lock cannot be greater than max");

		TOKEN.safeTransferFrom(_msgSender(), address(this), _amount);

		totalStaked += _amount;

		User memory user = users[_msgSender()];
		_payoutPendingGains(user);
		_updateUser(user, user.stakedAmount + _amount, _lockDuration);
	}
	
	function unstake(uint _amount) external {
		User memory user = users[_msgSender()];
		require(user.lockEndTime <= block.timestamp, "still locked");
		require(_amount <= user.stakedAmount, "amount too big");

		totalStaked -= _amount;

		_payoutPendingGains(user);
		_updateUser(user, user.stakedAmount - _amount, 0);

		TOKEN.safeTransfer(_msgSender(), _amount);
	}

	function claim() external {
		User storage user = users[_msgSender()];
		require(user.shares > 0, "nothing to claim");
		_payoutPendingGains(user);
		user.sumGPUS = sumGPUS;
	}

	function distribute(uint amount) external {
		require(_msgSender() == address(SPLITTER), "unauthorized");

		uint totalSharesCached = totalShares;
		if (totalSharesCached == 0) {
			TOKEN.safeTransfer(owner(), amount);
			return;
		}

		totalDistributed += amount;

		// compute gain per unit staked
		uint numerator = amount * PRECISION + lastRoundingError;
		uint gpus = numerator / totalSharesCached;

		// update rounding error from one iteration to another
		lastRoundingError = numerator - gpus * totalSharesCached;
		sumGPUS += gpus;
	}

	function setMaxLock(uint _maxLockDuration, uint _maxLockBonus) external onlyOwner {
		maxLockDuration = _maxLockDuration;
		maxLockBonus = _maxLockBonus;
		emit SetMaxLock(_maxLockDuration, _maxLockBonus);
	}

	function pendingOf(address who) external view returns (uint) {
		User memory user = users[who];
		if (user.shares == 0) return 0;
		uint sumGPUSUpdated = sumGPUS + SPLITTER.pendingOf(address(this)) * PRECISION / totalShares;
		return user.shares * (sumGPUSUpdated - user.sumGPUS) / PRECISION;
	}

	function _updateUser(User memory user, uint newStakedAmount, uint lockDuration) private {
		if (newStakedAmount == 0) { // fully unstaked
			totalShares -= user.shares;
			delete users[_msgSender()];
			return;
		}

		if (user.stakedAmount == 0) { // first deposit
			uint shares = _computeUserShares(newStakedAmount, lockDuration);
			uint lockEndTime = block.timestamp + lockDuration;

			users[_msgSender()] = User(newStakedAmount, shares, block.timestamp, lockEndTime, sumGPUS);
			totalShares += shares;
		} else {
			if (user.lockEndTime > block.timestamp) {
				lockDuration += user.lockEndTime - block.timestamp;

				uint maxLockDurationCached = maxLockDuration;
				if (lockDuration > maxLockDurationCached) lockDuration = maxLockDurationCached;
			}

			uint shares =  _computeUserShares(newStakedAmount, lockDuration);
			uint lockEndTime = block.timestamp + lockDuration;

			users[_msgSender()] = User(newStakedAmount, shares, block.timestamp, lockEndTime, sumGPUS);
			totalShares = totalShares - user.shares + shares;
		}
	}

	// caller to update user.sumGPUS
	function _payoutPendingGains(User memory user) private {
		SPLITTER.split();
		if (user.shares == 0) return;
		uint gains = user.shares * (sumGPUS - user.sumGPUS) / PRECISION;
		if (gains > 0) TOKEN.safeTransfer(_msgSender(), gains);
	}

	function _computeUserShares(uint stakedAmount, uint lockDuration) internal view returns (uint) {
		uint maxLockDurationCached = maxLockDuration;
		if (maxLockDurationCached == 0) return stakedAmount;
		return stakedAmount + stakedAmount * maxLockBonus * lockDuration / maxLockDurationCached / PRECISION;
	}
}
