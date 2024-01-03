// SPDX-License-Identifier: MIT
// Forked from Uniswap Liquidity Staking contract

pragma solidity ^ 0.6.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./QPoolRewards.sol";

contract QPoolStakingFactory is Ownable {
    using SafeMath for uint256;
    // immutables
    address public rewardsToken;
    uint public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] private stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint rewardAmount;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');
        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, uint rewardAmount, uint stakingDuration) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');
        info.stakingRewards = address(new QPoolRewards(address(this), rewardsToken, stakingToken, stakingDuration));
        info.rewardAmount = rewardAmount;
        stakingTokens.push(stakingToken);
    }
    
    function updateStakingRewards(address stakingToken, uint rewardAmount) public onlyOwner returns (uint256 newReward) {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        info.rewardAmount = info.rewardAmount.add(rewardAmount);
        return info.rewardAmount;
    }
    
    ///// view functions
    
    // get list of qpool token addresses for staking
    
    function getTokens() public view returns (address[] memory) {
        return stakingTokens;
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
            QPoolRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        }
    }
}