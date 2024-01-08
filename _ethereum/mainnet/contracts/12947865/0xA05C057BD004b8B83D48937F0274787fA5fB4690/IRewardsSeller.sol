// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IRewardsSeller {
  /**
   * @dev Sell `rewardsToken` for `underlyingToken`.
   * Should only be called after `rewardsToken` is transferred.
   * @param sender - Address of account that initially triggered the call. Can be used to restrict who can trigger a sale.
   * @param rewardsToken - Address of the token to sell.
   * @param underlyingToken - Address of the token to buy.
   * @param params - Any additional data that the caller provided.
   */
  function sellRewards(
    address sender,
    address rewardsToken,
    address underlyingToken,
    bytes calldata params
  ) external;
}