// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAuraClaimZapV3 {
  /**
   * @dev Claim rewards amounts.
   * - depositCrvMaxAmount    The max amount of CRV to deposit if converting to crvCvx
   * - minAmountOut           The min amount out for crv:cvxCrv swaps if swapping. Set this to zero if you
   *                          want to use CrvDepositor instead of balancer swap
   * - depositCvxMaxAmount    The max amount of CVX to deposit if locking CVX
   * - depositCvxCrvMaxAmount The max amount of CVXCVR to stake.
   */
  struct ClaimRewardsAmounts {
    uint256 depositCrvMaxAmount;
    uint256 minAmountOut;
    uint256 depositCvxMaxAmount;
    uint256 depositCvxCrvMaxAmount;
  }

  /**
   * @dev options.
   * - claimCvxCrv             Flag: claim from the cvxCrv rewards contract
   * - claimLockedCvx          Flag: claim from the cvx locker contract
   * - lockCvxCrv              Flag: pull users cvxCrvBalance ready for locking
   * - lockCrvDeposit          Flag: locks crv rewards as cvxCrv
   * - useAllWalletFunds       Flag: lock rewards and existing balance
   * - useCompounder           Flag: deposit cvxCrv into autocompounder
   * - lockCvx                 Flag: lock cvx rewards in locker
   */
  struct Options {
    bool claimCvxCrv;
    bool claimLockedCvx;
    bool lockCvxCrv;
    bool lockCrvDeposit;
    bool useAllWalletFunds;
    bool useCompounder;
    bool lockCvx;
  }

  /**
   * @notice Claim all the rewards
   * @param rewardContracts        Array of addresses for LP token rewards
   * @param extraRewardContracts   Array of addresses for extra rewards
   * @param tokenRewardContracts   Array of addresses for token rewards e.g vlCvxExtraRewardDistribution
   * @param tokenRewardTokens      Array of token reward addresses to use with tokenRewardContracts
   * @param amounts                Claim rewards amounts.
   * @param options                Claim options
   */
  function claimRewards(
    address[] calldata rewardContracts,
    address[] calldata extraRewardContracts,
    address[] calldata tokenRewardContracts,
    address[] calldata tokenRewardTokens,
    ClaimRewardsAmounts calldata amounts,
    Options calldata options
  ) external;
}