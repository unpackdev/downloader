pragma solidity ^0.5.16;

import "./IERC20.sol";
import "./Ownable.sol";

import "./StakingRewards.sol";

contract StakingRewardsFactory is Ownable {
    using SafeMath for uint;

    // immutables
    address public rewardsToken;
    uint public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint rewardAmount;
        uint rewardProgressAmount;
        uint rewardTotalAmount;
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
    function deploy(address stakingToken, uint rewardAmount, uint rewardTotalAmount) public onlyOwner {
        require(rewardAmount <= rewardTotalAmount, 'StakingRewardsFactory::deploy: rewardAmount must be less or equal rewardTotalAmount');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');

        info.stakingRewards = address(new StakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken));
        info.rewardAmount = rewardAmount;
        info.rewardProgressAmount = 0;
        info.rewardTotalAmount = rewardTotalAmount;
        stakingTokens.push(stakingToken);
    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public onlyOwner {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingTokens[i]];
            require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

            notifyRewardAmount(stakingTokens[i], info.rewardAmount);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken, uint rewardAmount) public onlyOwner {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardProgressAmount < info.rewardTotalAmount) {
            uint remaining = info.rewardTotalAmount.sub(info.rewardProgressAmount);
            require(remaining >= rewardAmount, 'StakingRewardsFactory::notifyRewardAmount: incorrect rewardAmount');

            info.rewardProgressAmount = info.rewardProgressAmount.add(rewardAmount);
            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        }
    }
}