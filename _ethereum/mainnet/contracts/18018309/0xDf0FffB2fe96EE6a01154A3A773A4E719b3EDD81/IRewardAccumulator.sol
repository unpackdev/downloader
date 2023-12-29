// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author charlescrain
/// @title IRewardAccumulator
/// @notice The reward accumulator interface containing all functions, events, etc. for accumulating and swapping rewards.
interface IRewardAccumulator {
  /*//////////////////////////////////////////////////////////////////////////
                              Events
  //////////////////////////////////////////////////////////////////////////*/

  event RewardAccumulator(address indexed _msgSender, address indexed _tokenOut, uint256 _amountOut, uint256 _rareIn);

  /*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Error emitted when a parameter is too low.
  error ParameterValueTooLow();

  /// @notice Error emitted when user doesnt meet the criteria for call.
  error Unauthorized();

  /// @notice Error emitted via {rewardSwap} if reward swap doesn't have enough funds to perform the swap.
  error InsufficientFunds();

  /// @notice Error emitted via {rewardSwap} if the rare price is too low to handle the _minAmountOut requirement.
  error RarePriceTooLow();

  /// @notice Error emitted via {rewardSwap} if _tokenOut is the $RARE address.
  error CannotSwapRareForRare();

  /// @notice Emitted when an unsupported ERC20 token for reward swapping.
  error UnsupportedERC20Token();

  /*//////////////////////////////////////////////////////////////////////////
                              Initializer
  //////////////////////////////////////////////////////////////////////////*/
  function initialize(address _stakingPool) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Swap RARE for a discounted price on tokens stored
  /// @param _tokenOut Address of the ERC20 to pay out with. If null address, then uses ETH.
  /// @param _minAmountOut Min amount one is willing to receive for the _rareIn.
  /// @param _rareIn The amount of RARE one is looking to trade.
  function rewardSwap(
    address _tokenOut,
    uint256 _minAmountOut,
    uint128 _rareIn
  ) external;

  /*//////////////////////////////////////////////////////////////////////////
                          External Read Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Estimate the discounted $RARE price for a given token.
  /// @param _tokenOut Address of the ERC20 token to be swapped for.
  /// @param _rareAmountIn uint128 amount of RARE to trade for the _tokenOut.
  /// @return uint256 amount of _tokenOut for the _rareAmountIn.
  function estimateRarePrice(address _tokenOut, uint128 _rareAmountIn) external view returns (uint256);
}
