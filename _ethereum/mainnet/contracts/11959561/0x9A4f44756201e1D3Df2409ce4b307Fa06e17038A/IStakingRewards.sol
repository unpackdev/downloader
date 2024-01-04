pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IStakingRewards {
  // Time Views
  function lastTimeRewardApplicable() external view returns (uint256);

  function lastUpdateTime() external view returns (uint256);

  function periodFinish() external view returns (uint256);

  function rewardsDuration() external view returns (uint256);

  // Reward Views
  function rewardPerToken() external view returns (uint256);

  function rewardPerTokenStored() external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  function rewardRate() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  // Token Views

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  // Configuration Views

  function stakingToken() external view returns (IERC20);

  function rewardsToken() external view returns (IERC20);

  // Mutative
  function initialize(address stakingToken, uint256 rewardsDuration) external;

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;

  // Restricted
  function notifyRewardAmount(uint256 reward) external;

  function recoverERC20(address tokenAddress, address recipient) external;

  function setRewardsDuration(uint256 rewardsDuration) external;
}
