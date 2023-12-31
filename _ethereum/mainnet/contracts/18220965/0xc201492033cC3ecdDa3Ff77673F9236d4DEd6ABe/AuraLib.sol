// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./SafeERC20.sol";

import "./IAuraBooster.sol";
import "./IBaseRewards.sol";
import "./IAuraClaimZapV3.sol";
import "./BalancerLib.sol";
import "./IStaker.sol";
import "./ConfigAaveBalAura.sol";

library AuraLibPub {
  using SafeERC20 for IERC20;

  /******************************************************
   *                                                    *
   *                  ACTIONS FUNCTIONS                 *
   *                                                    *
   ******************************************************/
  
  function harvest(address _booster, address _auraClaimZapV3, uint256 _pid) external {
    (,,,address rewardContract,,) = IAuraBooster(_booster).poolInfo(_pid);
    uint256 extraRewardsLength = IBaseRewards(rewardContract).extraRewardsLength();
    address[] memory extraRewardContracts = new address[](extraRewardsLength);

    for(uint256 i = 0; i < extraRewardsLength;) {
      extraRewardContracts[i] = IBaseRewards(rewardContract).extraRewards(i);
      unchecked { ++i; }
    }

    address[] memory rewardContracts = new address[](1);
    rewardContracts[0] = rewardContract;
    IAuraClaimZapV3(_auraClaimZapV3).claimRewards(
      rewardContracts,
      extraRewardContracts,
      new address[](0),
      new address[](0),
      IAuraClaimZapV3.ClaimRewardsAmounts(0, 0, 0, 0),
      IAuraClaimZapV3.Options(false, false, false, false, false, false, false)
    );
  }

  // Remove liquidity from Aura and Balancer
  function removeLiqAuraBal2Pools(
    Config.Data memory config,
    uint256 _withdrawMin,
    uint256 _stakedWithdrawAmount
  ) external {
    IBaseRewards(config.auraContracts.stakingToken).withdraw(_stakedWithdrawAmount, false); // TODO: maybe claim should be true
    IAuraBooster(config.auraContracts.booster).withdraw(config.poolIds.pidAura, _stakedWithdrawAmount);

    // Remove liquidity from Balancer (Pool 2)
    uint256 bptPool1Amount = BalancerLib.getTokenOutGivenExactBptInStable(
      config.balancerContracts.balancerVault, 
      config.poolIds.poolId2, 
      config.balancerContracts.bptPool1, 
      config.balancerContracts.bptPool2, 
      type(uint).max
    );
    BalancerLib.balancerExit(
      config.balancerContracts.balancerVault, 
      config.poolIds.poolId2, 
      config.balancerContracts.bptPool1, 
      IERC20(config.balancerContracts.bptPool2).balanceOf(address(this)), 
      bptPool1Amount * _withdrawMin / 1 ether
    );

    // Remove liquidity from Balancer (Pool 1)
    uint256[] memory withdrawAmounts = BalancerLib.getTokensOutGivenExactBptInWeighted(
      config.balancerContracts.balancerVault, 
      config.poolIds.poolId1, 
      config.balancerContracts.bptPool1, 
      type(uint).max
    );

    uint256[] memory minAmounts = new uint256[](2);
    minAmounts[0] = withdrawAmounts[0] * _withdrawMin / 1 ether;
    minAmounts[1] = withdrawAmounts[1] * _withdrawMin / 1 ether;

    BalancerLib.balancerExitMany(
      config.balancerContracts.balancerVault, 
      config.poolIds.poolId1, 
      IERC20(config.balancerContracts.bptPool1).balanceOf(address(this)), 
      minAmounts
    );
  }

  function calcRemoveLiqAuraBal2Pools(
    address _vault,
    bytes32 _pid1,
    bytes32 _pid2,
    address _bptPool1,
    address _bptPool2,
    uint256 _stakedWithdrawAmount
  ) public view returns(uint256[] memory withdrawAmounts) {
    uint256 bptPool1Amount = BalancerLib.getTokenOutGivenExactBptInStable(_vault, _pid2, _bptPool1, _bptPool2, _stakedWithdrawAmount);
    withdrawAmounts = BalancerLib.getTokensOutGivenExactBptInWeighted(_vault, _pid1, _bptPool1, bptPool1Amount);
  }

  /******************************************************
   *                                                    *
   *                    VIEW FUNCTIONS                  *
   *                                                    *
   ******************************************************/

  // Get total underlying liquidity on Aura
  function getUnderlyingAuraBal2Pools(
    address _bptPool1,
    address _bptPool2,
    address _stakingToken,
    bytes32 _poolId1,
    bytes32 _poolId2,
    address _vault
  ) external view returns(uint256, uint256) {
    uint256 bptPool2Amount = IERC20(_stakingToken).balanceOf(address(this));

    uint256[] memory withdrawAmounts = calcRemoveLiqAuraBal2Pools(
      _vault,
      _poolId1,
      _poolId2,
      _bptPool1,
      _bptPool2,
      bptPool2Amount
    );

    return (withdrawAmounts[0], withdrawAmounts[1]);
  }
}

library AuraLib {
  function harvest(address _booster, address _auraClaimZapV3, uint256 _pid) internal {
    AuraLibPub.harvest(_booster, _auraClaimZapV3, _pid);
  }

  function removeLiqAuraBal2Pools(
    Config.Data memory config,
    uint256 _withdrawMin,
    uint256 _stakedWithdrawAmount
  ) internal {
    return AuraLibPub.removeLiqAuraBal2Pools(
      config,
      _withdrawMin,
      _stakedWithdrawAmount
    );
  }

  function getUnderlyingAuraBal2Pools(
    address _bptPool1,
    address _bptPool2,
    address _stakingToken,
    bytes32 _poolId1,
    bytes32 _poolId2,
    address _vault
  ) internal view returns(uint256, uint256) {
    return AuraLibPub.getUnderlyingAuraBal2Pools(
      _bptPool1,
      _bptPool2,
      _stakingToken,
      _poolId1,
      _poolId2,
      _vault
    );
  }
}