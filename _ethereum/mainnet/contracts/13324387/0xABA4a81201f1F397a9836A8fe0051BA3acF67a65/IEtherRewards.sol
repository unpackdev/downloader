// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IEtherRewards {
  /// @param token The address of the token ERC20 contract
  /// @param user The address of the user
  function updateUserRewards(address token, address user) external;

  /// @param token The address of the token ERC20 contract
  /// @param ethRewardsAmount The amount of Ether rewards to add
  function increaseEthRewards(address token, uint256 ethRewardsAmount) external;

  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function claimEthRewards(address user) external returns (uint256 ethRewards);

  /// @param token The address of the token ERC20 contract
  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function getUserTokenEthRewards(address token, address user)
    external
    view
    returns (uint256 ethRewards);

  /// @param user The address of the user
  /// @return ethRewards The amount of Ether claimed
  function getUserEthRewards(address user)
    external
    view
    returns (uint256 ethRewards);

  /// @param token The address of the token ERC20 contract
  /// @return The amount of Ether rewards for the specified token
  function getTokenEthRewards(address token) external view returns (uint256);

  /// @return The total value of ETH claimed by users
  function getTotalClaimedEthRewards() external view returns (uint256);

  /// @return The total value of ETH claimed by a user
  function getTotalUserClaimedEthRewards(address user)
    external
    view
    returns (uint256);

  /// @return The total amount of Ether rewards
  function getEthRewards() external view returns (uint256);
}
