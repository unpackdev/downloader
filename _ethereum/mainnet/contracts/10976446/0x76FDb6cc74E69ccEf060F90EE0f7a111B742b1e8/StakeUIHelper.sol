// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./StakedToken.sol";
import "./AaveDistributionManager.sol";
import "./StakeUIHelperI.sol";
import "./IERC20WithNonce.sol";

contract StakeUIHelper is StakeUIHelperI {
  IERC20WithNonce immutable AAVE;
  StakedToken immutable STAKED_AAVE;

  constructor(IERC20WithNonce aave, StakedToken stkAave) public {
    AAVE = aave;
    STAKED_AAVE = stkAave;
  }

  function getUserUIData(address user) external override view returns (AssetUIData memory) {
    AssetUIData memory data;

    data.stkAaveTotalSupply = STAKED_AAVE.totalSupply();
    data.stakeCooldownSeconds = STAKED_AAVE.COOLDOWN_SECONDS();
    data.stakeUnstakeWindow = STAKED_AAVE.UNSTAKE_WINDOW();
    (data.distributionPerSecond, , ) = STAKED_AAVE.assets(address(STAKED_AAVE));

    if (user != address(0)) {
      data.aaveUserBalance = AAVE.balanceOf(user);
      data.stkAaveUserBalance = STAKED_AAVE.balanceOf(user);
      data.userIncentivesToClaim = STAKED_AAVE.getTotalRewardsBalance(user);
      data.userCooldown = STAKED_AAVE.stakersCooldowns(user);
      data.userPermitNonce = AAVE._nonces(user);
    }
    return data;
  }
}
