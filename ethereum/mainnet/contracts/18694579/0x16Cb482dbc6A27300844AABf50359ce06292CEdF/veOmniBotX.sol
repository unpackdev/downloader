// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ISplitter.sol";
import "./IReceiver.sol";

contract veOmniBotX is ERC20, Ownable, IReceiver {
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
	uint internal constant PRECISION = 1 ether;

	mapping(address => User) public users;
	uint public totalDistributed;
	uint public totalStaked;
	uint public totalShares;
	uint public sumGPUS;
	uint public lastRoundingError;
	uint public maxLockDuration;
	uint public maxLockBonus; // 1 ether == 100%
	uint public maxUnlockFee; // 0.1 ether == 10%
	uint public minUnlockFee; // 0.1 ether == 10%
	bool public canUnlockWithFee;
	address public taxReceiver;

	event SetMaxLock(uint _maxLockDuration, uint _maxLockBonus);
	event SetUnlockFee(uint _minUnlockFee, uint _maxUnlockFee);
	event SetCanUnlockWithFee(bool __canUnlockWithFee);
	event SetTaxReceiver(address who);

	constructor(
		string memory _name,
		string memory _symbol,
		IERC20 _token, 
		ISplitter _splitter
	)
		ERC20(_name, _symbol)
	{
		TOKEN = _token;
		SPLITTER = _splitter;

		taxReceiver = _msgSender();
		emit SetTaxReceiver(_msgSender());
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

		if (_amount > 0) TOKEN.safeTransfer(_msgSender(), _amount);
	}

	function claim() external {
		User storage user = users[_msgSender()];
		require(user.shares > 0, "nothing to claim");
		_payoutPendingGains(user);
		user.sumGPUS = sumGPUS;
	}

	function unlockWithFee() external {
		require(canUnlockWithFee, "unlock with fee disabled");
		User memory user = users[_msgSender()];
		
		totalStaked -= user.stakedAmount;
		uint feeAmount = computeUnlockFee(_msgSender());
		uint amount = user.stakedAmount - feeAmount;

		_payoutPendingGains(user);
		_updateUser(user, 0, 0);

		if (amount > 0) TOKEN.safeTransfer(_msgSender(), amount);
		if (feeAmount > 0) TOKEN.safeTransfer(taxReceiver, feeAmount);
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
	
	function setUnlockFee(uint _minUnlockFee, uint _maxUnlockFee) external onlyOwner {
		require(_minUnlockFee <= _maxUnlockFee, "fee discrepency");
		require(_maxUnlockFee <= PRECISION, "cannot be greater than precision");
		minUnlockFee = _minUnlockFee;
		maxUnlockFee = _maxUnlockFee;
		emit SetUnlockFee(_minUnlockFee, _maxUnlockFee);
	}

	function setCanUnlockWithFee(bool _canUnlockWithFee) external onlyOwner {
		canUnlockWithFee = _canUnlockWithFee;
		emit SetCanUnlockWithFee(_canUnlockWithFee);
	}

	function setTaxReceiver(address _who) external onlyOwner {
		assert(_who != address(0));
		taxReceiver = _who;
		emit SetTaxReceiver(_who);
	}

	function pendingOf(address who) external view returns (uint) {
		User memory user = users[who];
		if (user.shares == 0) return 0;
		uint sumGPUSUpdated = sumGPUS + SPLITTER.pendingOf(address(this)) * PRECISION / totalShares;
		return user.shares * (sumGPUSUpdated - user.sumGPUS) / PRECISION;
	}
	
	function computeUnlockFee(address who) public view returns (uint) {
		User memory user = users[who];
		if (user.stakedAmount == 0) return 0;
		if (block.timestamp >= user.lockEndTime) return 0;

		uint currentLockDuration = block.timestamp - user.lockStartTime;
		uint initialLockDuration = user.lockEndTime - user.lockStartTime;

		uint maxUnlockFeeCached = maxUnlockFee;
		uint feeDiff = maxUnlockFeeCached - minUnlockFee;
		uint feePerc = maxUnlockFeeCached - currentLockDuration * feeDiff / initialLockDuration;

		return user.stakedAmount * feePerc / PRECISION;
	}

	function _updateUser(User memory user, uint newStakedAmount, uint lockDuration) private {
		if (newStakedAmount == 0) { // fully unstaked
			totalShares -= user.shares;
			_burn(_msgSender(), user.shares);
			delete users[_msgSender()];
			return;
		}

		if (user.stakedAmount == 0) { // first deposit
			uint shares = _computeUserShares(newStakedAmount, lockDuration);
			uint lockEndTime = block.timestamp + lockDuration;

			users[_msgSender()] = User(newStakedAmount, shares, block.timestamp, lockEndTime, sumGPUS);
			_mint(_msgSender(), shares);

			totalShares += shares;
		} else {
			if (user.lockEndTime > block.timestamp) { // currently locked
				uint initialLockDuration = user.lockEndTime - user.lockStartTime;
				if (lockDuration < initialLockDuration) lockDuration = initialLockDuration;
			}

			uint shares =  _computeUserShares(newStakedAmount, lockDuration);
			uint lockEndTime = block.timestamp + lockDuration;

			_burn(_msgSender(), user.shares);
			users[_msgSender()] = User(newStakedAmount, shares, block.timestamp, lockEndTime, sumGPUS);
			_mint(_msgSender(), shares);

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

	function _transfer(address from, address to, uint256 amount) internal override {
		revert("cannot transfer");
	}
}
