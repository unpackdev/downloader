// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IBiosRewards {
  /// @param token The address of the ERC20 token contract
  /// @param reward The updated reward amount
  /// @param duration The duration of the rewards period
  function notifyRewardAmount(
    address token,
    uint256 reward,
    uint32 duration
  ) external;

  function increaseRewards(
    address token,
    address account,
    uint256 amount
  ) external;

  function decreaseRewards(
    address token,
    address account,
    uint256 amount
  ) external;

  function claimReward(address asset, address account)
    external
    returns (uint256 reward);

  function lastTimeRewardApplicable(address token)
    external
    view
    returns (uint256);

  function rewardPerToken(address token) external view returns (uint256);

  function earned(address token, address account)
    external
    view
    returns (uint256);

  function getUserBiosRewards(address account)
    external
    view
    returns (uint256 userBiosRewards);

  function getTotalClaimedBiosRewards() external view returns (uint256);

  function getTotalUserClaimedBiosRewards(address account)
    external
    view
    returns (uint256);

  function getBiosRewards() external view returns (uint256);
}
