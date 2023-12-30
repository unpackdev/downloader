// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface StakeUIHelperI {
  struct AssetUIData {
    uint256 stkAaveTotalSupply;
    uint256 stakeCooldownSeconds;
    uint256 stakeUnstakeWindow;
    uint128 distributionPerSecond;
    uint256 stkAaveUserBalance;
    uint256 aaveUserBalance;
    uint256 userCooldown;
    uint256 userIncentivesToClaim;
    uint256 userPermitNonce;
  }

  function getUserUIData(address user) external view returns (AssetUIData memory);
}
