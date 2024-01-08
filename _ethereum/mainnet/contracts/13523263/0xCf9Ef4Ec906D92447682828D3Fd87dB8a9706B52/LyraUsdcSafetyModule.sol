// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./StakedTokenV3.sol";
import "./IERC20.sol";

/**
 * @title LyraUsdcSafetyModule
 * @notice Contract to stake USDC token, tokenize the position and get rewards, inheriting from AAVE StakedTokenV3
 * @author Lyra
 **/
contract LyraUsdcSafetyModule is StakedTokenV3 {
  string internal constant NAME = "Staked Usdc";
  string internal constant SYMBOL = "stkUSDC";
  uint8 internal constant DECIMALS = 18;

  constructor(
    IERC20 stakedToken,
    IERC20 rewardToken,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    uint128 distributionDuration
  )
    public
    StakedTokenV3(
      stakedToken,
      rewardToken,
      cooldownSeconds,
      unstakeWindow,
      rewardsVault,
      emissionManager,
      distributionDuration,
      NAME,
      SYMBOL,
      DECIMALS,
      address(0)
    )
  {}
}
