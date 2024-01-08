// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

import "./DistributionParams.sol";
import "./IComponentPool.sol";

contract Distribution is DistributionParams {
  using SafeERC20 for IERC20;

  constructor (StakingPool[] memory _stakingPools) {
    canSwap[msg.sender] = true;
    approveTokens();
    for (uint i = 0; i < _stakingPools.length; i ++) {
      stakingPools.push(_stakingPools[i]);
    }
  }

  /**
    @notice minCmpAmount must be set to prevent sandwich attack
    @param swaps Swaps to be processed
    @param minCmpAmount The minimum amount of CMP being distributed
  **/
  function swapAndDistribute(Swap[] memory swaps, uint usdcAmount, uint minCmpAmount) public s returns(uint[] memory, uint) {
    require(minCmpAmount != 0, "Distribution: attackable by sandwich");

    uint deadline = block.timestamp + 1;

    require(deadline >= lastDistribution + distributionPeriod, "Distribution: too early");

    uint[] memory swapResults_ = new uint[](swaps.length);
    // swap stables to USDC
    for (uint i = 0; i < swaps.length; i++) {
      IERC20(swaps[i].origin).safeApprove(swaps[i].pool, swaps[i].amount);
      swapResults_[i] = IComponentPool(swaps[i].pool).originSwap(swaps[i].origin, swaps[i].target, swaps[i].amount, 0, deadline);
    }

    // swap USDC to CMP
    usdcToCmpRouter.swapExactTokensForTokens(usdcAmount, 0, usdcToCMPPath(), address(this), deadline);

    uint cmpAmount = cmp.balanceOf(address(this));
    require(cmpAmount >= minCmpAmount, "Distribution: insufficient CMP amount");

    cmp.approve(address(singleStaking), cmpAmount);
    singleStaking.addReward(cmpAmount);

    for (uint i = 0; i < stakingPools.length; i ++) {
      StakingPool storage stakingPool = stakingPools[i];
      if (stakingPool.poolAddress == address(0)) {
        cmp.mint(sidechainDistributor, stakingPool.rewardAmount);
      } else {
        cmp.mint(address(this), stakingPool.rewardAmount);
        cmp.approve(stakingPool.poolAddress, stakingPool.rewardAmount);
        IStakingPool(stakingPool.poolAddress).addReward(stakingPool.rewardAmount);
      }
    }

    lastDistribution = deadline;


    return (swapResults_, cmpAmount);
  }

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution(Swap[] memory swaps, uint usdcAmount) external s returns(
    uint[] memory swapResults_,
    uint minCmpAmount_
  ) {
    if (usdcAmount == 0) {
      swapResults_ = new uint[](swaps.length);
      for (uint i = 0; i < swaps.length; i++) {
        IERC20(swaps[i].origin).safeApprove(swaps[i].pool, swaps[i].amount);
        swapResults_[i] = IComponentPool(swaps[i].pool).originSwap(swaps[i].origin, swaps[i].target, swaps[i].amount, 0, block.timestamp + 1);
      }
      return (swapResults_, 0);
    }
    (swapResults_, minCmpAmount_) = swapAndDistribute(swaps, usdcAmount, 1);
  }

  function changePoolOwner(address pool, address newOwner) external g {
    IStakingPool(pool).transferOwnership(newOwner);
  }
}
