//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";
import "./AddressUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";

contract Staking is 
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  IERC20 public stakingToken;

  // Reward to be paid out per second
  uint256 public rewardRate;
  uint256 constant public RATE_DEVIDER = 1e8;

  struct Staker {
    uint256 amount;
    uint256 updatedTime;
    uint256 endTime;
    uint256 reward;
  }
  mapping(address => Staker) public stakers;

  // Total staked
  uint256 public totalSupply;

  event Staked(
    address indexed user,
    uint256 amount,
    uint256 endTime,
    uint256 timestamp
  );

  event Unstaked(
    address indexed user,
    uint256 amount,
    uint256 timestamp
  );

  event RewardClaimed(
    address indexed user,
    uint256 reward,
    uint256 timestamp
  );

  function initialize(
    address _stakingToken,
    uint256 _rewardRate
  ) initializer public {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    stakingToken = IERC20(_stakingToken);
    rewardRate = _rewardRate;
  }

  function stake(uint256 _amount, uint256 _endTime) external {
    require(_amount > 0, "amount = 0");
    require(_endTime > block.timestamp, "End time must be greater than current time");

    stakingToken.transferFrom(msg.sender, address(this), _amount);

    Staker storage staker = stakers[msg.sender];
    require(_endTime > staker.endTime, "Can only increase endTime");

    staker.reward = staker.reward + calculateReward(msg.sender);
    staker.amount += _amount;
    staker.endTime = _endTime;
    staker.updatedTime = block.timestamp;

    totalSupply += _amount;

    emit Staked(msg.sender, _amount, _endTime, block.timestamp);
  }

  function unstake(uint256 _amount) external {
    require(_amount > 0, "amount = 0");

    Staker storage staker = stakers[msg.sender];
    require(staker.amount >= _amount, "Not enough staked tokens");
    require(staker.endTime < block.timestamp, "Can't unstake until endTime");

    staker.reward = staker.reward + calculateReward(msg.sender);
    staker.amount -= _amount;
    staker.updatedTime = block.timestamp;

    totalSupply -= _amount;

    stakingToken.transfer(msg.sender, _amount);

    emit Unstaked(msg.sender, _amount, block.timestamp);
  }

  function claimReward() external {
    Staker storage staker = stakers[msg.sender];
    uint256 reward = staker.reward + calculateReward(msg.sender);
    require(reward > 0, "No reward to claim");

    staker.reward = 0;
    staker.updatedTime = block.timestamp;

    stakingToken.transfer(msg.sender, reward);

    emit RewardClaimed(msg.sender, reward, block.timestamp);
  }

  function calculateReward(address user) public view returns (uint256) {
    Staker storage staker = stakers[user];
    return staker.amount * rewardRate * (block.timestamp - staker.updatedTime) / RATE_DEVIDER;
  }
}