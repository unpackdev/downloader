// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./GemlyToken.sol";
import "./GameToken.sol";
import "./Governable.sol";
import "./StakingPool.sol";

abstract contract RefillableStakingPool is StakingPool, ReentrancyGuard {
  using Address for address;
  using SafeERC20 for GemlyToken;
  using SafeERC20 for GameToken;

  GemlyToken public coreToken;
  GameToken public rewardToken;

  uint256 public duration = 7 days;
  uint256 public periodFinish = 0;
  uint256 public rewardAmount = 100 * 10 ** 18;
  uint256 public totalRewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);

  modifier updateReward(address _account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (_account != address(0)) {
      rewards[_account] = earned(_account);
      userRewardPerTokenPaid[_account] = rewardPerTokenStored;
    }
    _;
  }

  constructor(address _governance, address _coreToken, address _rewardToken) public
    StakingPool(_governance) {
      coreToken = GemlyToken(_coreToken);
      rewardToken = GameToken(_rewardToken);
  }

  function setReward(uint256 _rewardAmount, uint256 _duration) public onlyGovernance {
    rewardAmount = _rewardAmount;
    duration = _duration;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(totalRewardRate)
          .mul(1e18)
          .div(totalSupply)
      );
  }

  function rewardPerDuration(address _account, uint256 _duration) public view returns (uint256) {
    if (totalSupply == 0) {
      return 0;
    }
    return balanceOf(_account)
      .mul(totalRewardRate)
      .mul(_duration)
      .div(totalSupply);
  }

  function earned(address _account) public view returns (uint256) {
    return balanceOf(_account)
      .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
      .div(1e18)
      .add(rewards[_account]);
  }

  function stake(uint256 _amount) public override updateReward(msg.sender) nonReentrant {
    require(_amount > 0, "Cannot stake 0");
    super.stake(_amount);
    emit Staked(msg.sender, _amount);
  }

  function withdraw(uint256 _amount) public override updateReward(msg.sender) nonReentrant {
    require(_amount > 0, "Cannot withdraw 0");
    super.withdraw(_amount);

    emit Withdrawn(msg.sender, _amount);
  }

  function getReward() public updateReward(msg.sender) nonReentrant {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);

      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function refill() external {
    require(periodFinish == 0 || block.timestamp >= periodFinish - (15 minutes), "Distribution not yet over");

    rewardPerTokenStored = rewardPerToken();
    rewardToken.mint(address(this), rewardAmount);
    totalRewardRate = rewardAmount.div(duration);
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(duration);

    emit RewardAdded(rewardAmount);
  }
}
