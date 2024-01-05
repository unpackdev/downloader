// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./StakingControllerLib.sol";
import "./UpdateToLastImplLib.sol";

library UpdateToLastLib {
  function updateToLast(
    StakingControllerLib.Isolate storage isolate,
    address user
  ) external {
    UpdateToLastImplLib._updateToLast(isolate, user);
  }
  function updateWeightsWithMultiplier(
    StakingControllerLib.Isolate storage isolate,
    address user,
    uint256 multiplier
  ) external returns (uint256) {
    return UpdateToLastImplLib._updateWeightsWithMultiplier(isolate, user, multiplier);
  }
}
