// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMathUpgradeable.sol";
import "./CalculateRewardsImplLib.sol";
import "./StakingControllerLib.sol";

library CalculateRewardsLib {
  using SafeMathUpgradeable for *;

  function calculateRewards(
    StakingControllerLib.Isolate storage isolate,
    address _user,
    uint256 amt,
    bool isView
  ) external returns (uint256 amountToRedeem, uint256 bonuses) {
    (amountToRedeem, bonuses) = CalculateRewardsImplLib._calculateRewards(
      isolate,
      _user,
      amt,
      isView
    );
  }
}
