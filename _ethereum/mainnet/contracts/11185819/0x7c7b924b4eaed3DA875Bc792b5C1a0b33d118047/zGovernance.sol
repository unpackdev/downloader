// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./Math.sol";
import "./IRewardDistributionRecipient.sol";
import "./zLOTTokenWrapper.sol";

contract zGovernance is zLOTTokenWrapper, IRewardDistributionRecipient {
  uint256 public constant DURATION = 7 days;

  IERC20 public zToken;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime = 0;
  uint256 public rewardPerTokenStored = 0;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) public totalEarnedRewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward, uint256 totalEarnedRewards);

  constructor (address _zLOT, address _zToken) public zLOTTokenWrapper(_zLOT) {
    zToken = IERC20(_zToken);
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function stake(uint256 amount) override public updateReward(msg.sender) {
    require(amount > 0, 'zGovernance::stake::cant-stake-0');
    super.stake(amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) override public updateReward(msg.sender) {
    require(amount > 0, 'zGovernance::withdraw::cant-withdraw-0');
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward() public updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      totalEarnedRewards[msg.sender] = totalEarnedRewards[msg.sender].add(reward);
      zToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward, totalEarnedRewards[msg.sender]);
    }
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    IERC20(zToken).safeTransferFrom(msg.sender, address(this), reward);
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }
}