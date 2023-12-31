// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IPublicEndStakeable.sol";
import "./IHEX.sol";
import "./IHedron.sol";
import "./UnderlyingStakeable.sol";

contract MockPerpetual is IPublicEndStakeable {
  address internal constant TARGET = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
  address internal constant HEDRON = 0x3819f64f282bf135d62168C1e513280dAF905e06;
  function startStakeHEX() external {
    uint256 lockedDays = 1;
    STAKE_END_DAY = UnderlyingStakeable(TARGET).currentDay() + lockedDays;
    IHEX(TARGET).stakeStart(IHEX(TARGET).balanceOf(address(this)), lockedDays);
  }
  uint256 public STAKE_END_DAY = 0;
  bool public STAKE_IS_ACTIVE = true;
  uint256 public currentPeriod = 1;
  function mintHedron(uint256 stakeIndex, uint40 stakeIdParam) external {
    IHedron(HEDRON).mintNative(stakeIndex, stakeIdParam);
  }
  function endStakeHEX(uint256 stakeIndex, uint40 stakeIdParam) external {
    // these resets are handled by stake restarts
    // internally managed by perpetual contract
    STAKE_IS_ACTIVE = false;
    this.mintHedron(stakeIndex, stakeIdParam);
    IHEX(TARGET).stakeEnd(stakeIndex, stakeIdParam);
    currentPeriod++;
  }
  function getCurrentPeriod() external view returns (uint256) {
    return currentPeriod;
  }
}
