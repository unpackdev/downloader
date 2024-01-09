// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./StakedTokenV3.sol";
import "./IERC20.sol";

/**
 * @title LyraSafetyModule
 * @notice Contract to stake Lyra token, tokenize the position and get rewards, inheriting from AAVE StakedTokenV3
 * @author Lyra
 **/
contract LyraSafetyModule is StakedTokenV3 {
  string internal constant NAME = "Staked Lyra";
  string internal constant SYMBOL = "stkLYRA";
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
