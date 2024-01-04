// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import "./SafeMath.sol";
import "./TransferHelper.sol";

interface IERC20 {
	function approve(address spender, uint256 value) external returns (bool);

	function balanceOf(address owner) external view returns (uint256);
}

contract BaseShareField {
	using SafeMath for uint256;

	uint256 public totalProductivity;
	uint256 public accAmountPerShare;

	uint256 public totalShare;
	uint256 public mintedShare;
	uint256 public mintCumulation;

	uint256 private unlocked = 1;
	address public shareToken;

	modifier lock() {
		require(unlocked == 1, "Locked");
		unlocked = 0;
		_;
		unlocked = 1;
	}

	struct UserInfo {
		uint256 amount; // How many tokens the user has provided.
		uint256 rewardDebt; // Reward debt.
		uint256 rewardEarn; // Reward earn and not minted
		bool initialize; // already setup.
	}

	mapping(address => UserInfo) public users;

	function _setShareToken(address _shareToken) internal {
		shareToken = _shareToken;
	}

	// Update reward variables of the given pool to be up-to-date.
	function _update() internal virtual {
		if (totalProductivity == 0) {
			totalShare = totalShare.add(_currentReward());
			return;
		}

		uint256 reward = _currentReward();
		accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
		totalShare += reward;
	}

	function _currentReward() internal view virtual returns (uint256) {
		return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
	}

	// Audit user's reward to be up-to-date
	function _audit(address user) internal virtual {
		UserInfo storage userInfo = users[user];
		if (userInfo.amount > 0) {
			uint256 pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
			userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
			mintCumulation = mintCumulation.add(pending);
			userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		}
	}

	// External function call
	// This function increase user's productivity and updates the global productivity.
	// the users' actual share percentage will calculated by:
	// Formula:     user_productivity / global_productivity
	function _increaseProductivity(address user, uint256 value) internal virtual returns (bool) {
		require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");
		UserInfo storage userInfo = users[user];
		_update();
		_audit(user);
		totalProductivity = totalProductivity.add(value);
		userInfo.amount = userInfo.amount.add(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		return true;
	}

	// External function call
	// This function will decreases user's productivity by value, and updates the global productivity
	// it will record which block this is happenning and accumulates the area of (productivity * time)
	function _decreaseProductivity(address user, uint256 value) internal virtual returns (bool) {
		UserInfo storage userInfo = users[user];
		require(value > 0 && userInfo.amount >= value, "INSUFFICIENT_PRODUCTIVITY");

		_update();
		_audit(user);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		totalProductivity = totalProductivity.sub(value);

		return true;
	}

	function _transferTo(
		address user,
		address to,
		uint256 value
	) internal virtual returns (bool) {
		UserInfo storage userInfo = users[user];
		require(value > 0 && userInfo.amount >= value, "INSUFFICIENT_PRODUCTIVITY");

		_update();
		_audit(user);
		uint256 transferAmount = value.mul(userInfo.rewardEarn).div(userInfo.amount);
		userInfo.rewardEarn = userInfo.rewardEarn.sub(transferAmount);
		users[to].rewardEarn = users[to].rewardEarn.add(transferAmount);

		userInfo.amount = userInfo.amount.sub(value);
		userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
		totalProductivity = totalProductivity.sub(value);

		return true;
	}

	function _takeWithAddress(address user) internal view returns (uint256) {
		UserInfo storage userInfo = users[user];
		uint256 _accAmountPerShare = accAmountPerShare;
		if (totalProductivity != 0) {
			uint256 reward = _currentReward();
			_accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
		}
		return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
	}

	// External function call
	// When user calls this function, it will calculate how many token will mint to user from his productivity * time
	// Also it calculates global token supply from last time the user mint to this time.
	function _mint(address user) internal virtual lock returns (uint256) {
		_update();
		_audit(user);
		require(users[user].rewardEarn > 0, "NOTHING TO MINT SHARE");
		uint256 amount = users[user].rewardEarn;
		TransferHelper.safeTransfer(shareToken, user, amount);
		users[user].rewardEarn = 0;
		mintedShare += amount;
		return amount;
	}

	function _mintTo(address user, address to) internal virtual lock returns (uint256) {
		_update();
		_audit(user);
		uint256 amount = users[user].rewardEarn;
		if (amount > 0) {
			TransferHelper.safeTransfer(shareToken, to, amount);
		}

		users[user].rewardEarn = 0;
		mintedShare += amount;
		return amount;
	}

	// Returns how many productivity a user has and global has.
	function getProductivity(address user) public view virtual returns (uint256, uint256) {
		return (users[user].amount, totalProductivity);
	}

	// Returns the current gorss product rate.
	function interestsPerBlock() public view virtual returns (uint256) {
		return accAmountPerShare;
	}
}
