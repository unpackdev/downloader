//"SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract KeyTangoStaking2m {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	mapping(address => uint256) private _stakes;

	string public name;
	address private immutable tokenAddress;
	uint256 public immutable stakingStarts;
	uint256 public immutable stakingEnds;
	uint256 public stakedTotal;
	uint256 private immutable stakingCap;
	uint256 public stakedBalance;
	uint256 private constant ONE_MONTH = 30 days;
	uint256 private immutable DEPOSIT_TIME;
	uint256 private constant REWARD_PERC = 40; //40%
	address private constant REWARDADDRESS = 0xF6eCf57f84Cb9C9D49B4e5cA848D93857523f60a; //reward address

	IERC20 private immutable KeytangoToken;

	mapping(address => uint256) public deposited;

	event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);
	event PaidOut(address indexed token, address indexed staker_, uint256 amount_, uint256 reward_);
	event Refunded(address indexed token, address indexed staker_, uint256 amount_);

	modifier _positive(uint256 amount) {
		require(amount > 0, 'Error: negative amount');
		_;
	}

	modifier _after(uint256 eventTime) {
		require(block.timestamp >= eventTime, 'Error: bad timing for the request');
		_;
	}

	modifier _before(uint256 eventTime) {
		require(block.timestamp < eventTime, 'Error: bad timing for the request');
		_;
	}

	constructor(
		address keytango
	) public {
		require(keytango != address(0x0), 'Error: zero address');
		name = "Tango Staking";
		tokenAddress = keytango;
		KeytangoToken = IERC20(keytango);
		stakingStarts = block.timestamp;
		stakingEnds = block.timestamp.add(7 days);
		stakingCap = 100000 ether;
		DEPOSIT_TIME = ONE_MONTH.mul(2);
	}

	function stakeOf(address account) external view returns (uint256) {
		return _stakes[account];
	}

	function timeStaked(address account) external view returns (uint256) {
		return deposited[account];
	}

	function canWithdraw(address _addy) external view returns (bool) {
		if (block.timestamp >= deposited[_addy].add(DEPOSIT_TIME)) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Requirements:
	 * - `amount` Amount to be staked
	 */
	function stake(uint256 amount) external _positive(amount) {
		_stake(msg.sender, amount);
	}

	function withdraw(uint256 amount) external _positive(amount) {
		require(amount <= _stakes[msg.sender], 'Error: not enough balance');
		require(block.timestamp >= deposited[msg.sender].add(DEPOSIT_TIME), 'Error: Staking period not passed yet');
		_withdrawAfterClose(msg.sender, amount);
	}

	function _withdrawAfterClose(address from, uint256 amount) private {
		uint256 reward = amount.mul(REWARD_PERC).div(100);
		_stakes[from] = _stakes[from].sub(amount);
		stakedTotal = stakedTotal.sub(amount);
		stakedBalance = stakedBalance.sub(amount);
		KeytangoToken.safeTransferFrom(REWARDADDRESS, from, reward); //transfer Reward
		KeytangoToken.safeTransfer(from, amount); //transfer initial stake
		emit PaidOut(tokenAddress, from, amount, reward);
	}

	function _stake(address staker, uint256 amount) private _after(stakingStarts) _before(stakingEnds) {
		// check the remaining amount to be staked
		uint256 remaining = amount;
		if (remaining > (stakingCap.sub(stakedBalance))) {
			remaining = stakingCap.sub(stakedBalance);
		}
		// These requires are not necessary, because it will never happen, but won't hurt to double check
		// this is because stakedTotal and stakedBalance are only modified in this method during the staking period
		require(remaining > 0, 'Error: Staking cap is filled');
		require((remaining.add(stakedTotal)) <= stakingCap, 'Error: this will increase staking amount pass the cap');

		KeytangoToken.safeTransferFrom(staker, address(this), remaining);

		if (remaining < amount) {
			// Return the unstaked amount to sender (from allowance)
			uint256 refund = amount.sub(remaining);
			KeytangoToken.safeTransferFrom(address(this), staker, refund);
			emit Refunded(tokenAddress, staker, refund);
		}

		// Transfer is completed
		stakedBalance = stakedBalance.add(remaining);
		stakedTotal = stakedTotal.add(remaining);
		_stakes[staker] = _stakes[staker].add(remaining);
		deposited[msg.sender] = block.timestamp;
		emit Staked(tokenAddress, staker, amount, remaining);
	}
}
