// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMathUpgradeable.sol";
import "./StakingControllerLib.sol";
import "./MathUpgradeable.sol";
import "./UpdateToLastLib.sol";
import "./sCNFI.sol";
import "./ComputeCyclesHeldLib.sol";
import "./UpdateRedeemableImplLib.sol";

library UpdateRedeemableLib {
  using SafeMathUpgradeable for *;

  function determineMultiplier(
    StakingControllerLib.Isolate storage isolate,
    bool penaltyChange,
    address user,
    uint256 currentBalance
  ) external returns (uint256 multiplier, uint256 amountToBurn) {
    (multiplier, amountToBurn) = UpdateRedeemableImplLib._determineMultiplier(isolate, penaltyChange, user, currentBalance);
  }
  function updateCumulativeRewards(StakingControllerLib.Isolate storage isolate, address _user) internal {
    UpdateRedeemableImplLib._updateCumulativeRewards(isolate, _user);
  }
  function updateRedeemable(
    StakingControllerLib.Isolate storage isolate,
    StakingControllerLib.DailyUser storage user,
    uint256 multiplier
  ) external view returns (uint256 redeemable, uint256 bonuses) {
    (redeemable, bonuses) = UpdateRedeemableImplLib._updateRedeemable(isolate, user, multiplier);
  }
  function updateDailyStatsToLast(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 weight,
    bool penalize,
    bool init
  ) external returns (uint256 redeemable, uint256 bonuses) {
    (redeemable, bonuses) = UpdateRedeemableImplLib._updateDailyStatsToLast(isolate, sender, weight, penalize, init);
  }

  function recalculateDailyWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 newBalance,
    bool penalty
  ) external {
    UpdateRedeemableImplLib._recalculateDailyWeights(isolate, sender, newBalance, penalty);
  }

  function recalculateWeights(
    StakingControllerLib.Isolate storage isolate,
    address sender,
    uint256 oldBalance,
    uint256 newBalance,
    bool penalty
  ) external {
    UpdateRedeemableImplLib._recalculateWeights(isolate, sender, oldBalance, newBalance, penalty);
  }
  function determineDailyMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address sender
  ) external returns (uint256 multiplier) {
    multiplier = UpdateRedeemableImplLib._determineDailyMultiplier(isolate, sender);
  }
}
