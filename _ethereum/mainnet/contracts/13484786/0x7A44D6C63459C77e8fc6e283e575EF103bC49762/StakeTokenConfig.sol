// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IMarketAccessController.sol";
import "./IUnderlyingStrategy.sol";

struct StakeTokenConfig {
  IMarketAccessController stakeController;
  IERC20 stakedToken;
  IUnderlyingStrategy strategy;
  uint32 cooldownPeriod;
  uint32 unstakePeriod;
  uint16 maxSlashable;
  uint8 stakedTokenDecimals;
}
