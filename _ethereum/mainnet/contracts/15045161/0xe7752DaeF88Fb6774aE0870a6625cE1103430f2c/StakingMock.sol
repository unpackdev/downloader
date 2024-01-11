// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Math.sol";
import "./IStaking.sol";

// solhint-disable no-unused-vars
contract StakingMock is IStaking {
  address public override rewardsToken;

  address public override stakingToken;

  uint256 public override periodFinish;

  uint256 public override rewardRate;

  uint256 public override rewardsDuration;

  uint256 public override totalSupply;

  mapping(address => uint256) internal _rewards;

  mapping(address => uint256) internal _balances;

  constructor(
    address _rewardsToken,
    address _stakingToken,
    uint256 _rewardsDuration,
    uint256 _rewardRate
  ) {
    rewardsToken = _rewardsToken;
    stakingToken = _stakingToken;
    rewardsDuration = _rewardsDuration;
    rewardRate = _rewardRate;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function earned(address account) public view override returns (uint256) {
    return _rewards[account];
  }

  function stake(uint256 amount) external override {
    IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
    _balances[msg.sender] += amount;
    totalSupply += amount;
  }

  function withdraw(uint256 amount) public override {
    require(balanceOf(msg.sender) >= amount, "withdraw: transfer amount exceeds balance");

    _balances[msg.sender] -= amount;
    totalSupply -= amount;
    IERC20(stakingToken).transfer(msg.sender, amount);
  }

  function getReward() public override {
    uint256 reward = _rewards[msg.sender];
    require(reward > 0, "getReward: transfer amount exceeds balance");

    _rewards[msg.sender] = 0;
    IERC20(rewardsToken).transfer(msg.sender, reward);
  }

  function exit() external override {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function notifyRewardAmount(uint256 reward) external override {
    IERC20(rewardsToken).transferFrom(msg.sender, address(this), reward);
    _rewards[msg.sender] += reward;
    periodFinish = block.number + rewardsDuration;
  }

  function setReward(address account, uint256 amount) external {
    _rewards[account] += amount;
  }
}
