// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.12;

interface IContinuousRewardToken {
  /// @notice Emitted when a user supplies underlying token
  event Supply(address indexed sender, address indexed receiver, uint256 amount);
  /// @notice Emitted when a CRT token holder redeems balance
  event Redeem(address indexed sender, address indexed receiver, uint256 amount);
  /// @notice Emitted when current or previous reward owners claim their rewards
  event Claim(address indexed sender, address indexed receiver, address indexed rewardToken, uint256 amount);
  /// @notice Emitted when an admin changes current reward owner
  event DelegateUpdated(address indexed oldDelegate, address indexed newDelegate);
  /// @notice Emitted when an admin role is transferred by current admin
  event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

  /**
   * @notice The address of underlying token
   * @return underlying token
   */
  function underlying() external view returns (address);

  /**
   * @notice Unclaimed rewards of all previous owners: reward token => (owner => amount)
   * @param rewardToken Reward token address
   * @param owner Owner address
   * @return unclaimed rewards
   */
  function unclaimedRewards(address rewardToken, address owner) external view returns (uint256);

  /**
   * @notice Total amount of unclaimed rewards: (reward token => amount)
   * @param rewardToken Reward token address
   * @return total unclaimed rewards
   */
  function totalUnclaimedRewards(address rewardToken) external view returns (uint256);

  /**
   * @notice Reward tokens that may be accrued as rewards
   * @dev It's the responsibility of each implemantation to limit the size of the address array returned
   * @return Exhaustive list of all reward token addresses
   */
  function rewardTokens() external view returns (address[] memory);

  /**
   * @notice Balance of accrued reward token for account
   * @param rewardToken Reward token address
   * @param account Account address
   * @return Balance of accrued reward token for account
   */
  function balanceOfReward(address rewardToken, address account) external view returns (uint256);

  /**
   * @notice Annual Percentage Reward for the specific reward token. Measured in relation to the base units of the underlying asset vs base units of the accrued reward token.
   * @param rewardToken Reward token address
   * @return APY times 10^18
   */
  function rate(address rewardToken) external view returns (uint256);

  /**
   * @notice Supply a specified amount of underlying tokens and receive back an equivalent quantity of CB-CR-XX-XX tokens
   * @param receiver Account to credit CB-CR-XX-XX tokens to
   * @param amount Amount of underlying token to supply
   */
  function supply(
    address receiver,
    uint256 amount
  ) external;

  /**
   * @notice Redeem a specified amount of underlying tokens by burning an equivalent quantity of CB-CR-XX-XX tokens. Does not redeem reward tokens
   * @param receiver Account to credit underlying tokens to
   * @param amount Amount of underlying token to redeem
   */
  function redeem(
    address receiver,
    uint256 amount
  ) external;

  /**
   * @notice Claim accrued reward in one or reward tokens
   * @dev All params must have the same array length
   * @param receivers List of accounts to credit claimed tokens to
   * @param tokens Reward token addresses
   * @param amounts Amounts of each reward token to claim
   */
  function claim(
    address[] calldata receivers,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
   * @notice Atomic redeem and claim in a single transaction
   * @dev receivers.length[0] corresponds to the address that the underlying token is redeemed to. receivers.length[1:n-1] hold the to addresses for the reward tokens respectively.
   * @param receivers       List of accounts to credit tokens to
   * @param amounts         List of amounts to credit
   * @param claimTokens     Reward token addresses
   */
  function redeemAndClaim(
    address[] calldata receivers,
    uint256[] calldata amounts,
    address[] calldata claimTokens
  ) external;

  /**
   * @notice Snapshots reward owner balance and update reward owner address
   * @dev Only callable by admin
   * @param newDelegate New reward owner address
   */
  function updateDelegate(address newDelegate) external;

  /**
   * @notice Get the current delegate (receiver of rewards)
   * @return the address of the current delegate
   */
  function delegate() external view returns (address);

  /**
   * @notice Get the current admin
   * @return the address of the current admin
   */
  function admin() external view returns (address);

  /**
   * @notice Updates the admin address
   * @dev Only callable by admin
   * @param newAdmin New admin address
   */
  function transferAdmin(address newAdmin) external;
}
