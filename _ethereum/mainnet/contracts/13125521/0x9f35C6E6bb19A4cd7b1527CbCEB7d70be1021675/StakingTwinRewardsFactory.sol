// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Ownable.sol';
import "StakingTwinRewards.sol";

interface IFeSwapPair {
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
}

contract StakingTwinRewardsFactory is Ownable {
    // immutables
    address public rewardsToken;
    uint    public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingTwinToken;
        address stakingRewards;
        uint    rewardAmount;
        uint    rewardsDuration;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _rewardsToken,
        uint    _stakingRewardsGenesis
    ) Ownable() {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingTokenA, address stakingTokenB, uint rewardAmount, uint rewardsDuration) public onlyOwner {
        require(stakingTokenA < stakingTokenB, "Wrong token order");
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingTokenA];
        if(info.stakingRewards == address(0)) {
            require(IFeSwapPair(stakingTokenA).tokenIn() == IFeSwapPair(stakingTokenB).tokenOut(), "Wrong pair token");
            require(IFeSwapPair(stakingTokenA).tokenOut() == IFeSwapPair(stakingTokenB).tokenIn(), "Wrong pair token");

            info.stakingRewards = address(new StakingTwinRewards(/*_rewardsDistribution=*/ address(this), 
                                                                rewardsToken, stakingTokenA, stakingTokenB));
            info.stakingTwinToken = stakingTokenB;
            info.rewardAmount = rewardAmount;
            info.rewardsDuration = rewardsDuration;
            stakingTokens.push(stakingTokenA);
        } else {
            require(info.rewardAmount == 0, 'StakingRewardsFactory::deploy: already deployed');
            require(stakingTokenB == info.stakingTwinToken, "Wrong twin token");
            info.rewardAmount = rewardAmount;                   // refill the reward contract
            info.rewardsDuration = rewardsDuration;
        }

    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            StakingTwinRewards(info.stakingRewards).notifyRewardAmount(rewardAmount, info.rewardsDuration);
        }
    }
}