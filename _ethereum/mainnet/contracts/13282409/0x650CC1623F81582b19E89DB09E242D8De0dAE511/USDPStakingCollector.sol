// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./IUSDPStaking.sol";

contract USDPStakingCollector {

  IERC20 public constant usdp = IERC20(0x1456688345527bE1f37E9e627DA0837D6f08C925);

  // TODO: set the address
  IUSDPStaking public immutable usdpStaking;

  uint public lastDistribution;

  event Distributed(uint usdpAmout);

  constructor (address _usdpStaking) {
    usdpStaking = IUSDPStaking(_usdpStaking);
  }

  function distribute() external {
    require(block.timestamp >= lastDistribution / 1 weeks * 1 weeks + 1 weeks, "StabilityFeeCollector: premature");

    uint usdpAmount = usdp.balanceOf(address(this));
    usdp.approve(address(usdpStaking), usdpAmount);
    usdpStaking.addReward(usdpAmount);
    lastDistribution = block.timestamp;

    emit Distributed(usdpAmount);
  }
}
