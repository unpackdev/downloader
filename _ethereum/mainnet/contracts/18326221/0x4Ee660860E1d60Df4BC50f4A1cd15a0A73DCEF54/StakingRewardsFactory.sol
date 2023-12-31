// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./StakingRewards.sol";
import "./IStakingRewardsFactory.sol";

contract StakingRewardsFactory is Ownable, IStakingRewardsFactory {
    // immutables
    uint256 public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        address rewardToken;
        uint256 rewardAmount;
        uint256 duration;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo)
        public stakingRewardsInfoByStakingToken;

    constructor(uint256 _stakingRewardsGenesis) Ownable() {
        require(_stakingRewardsGenesis >= block.timestamp, "GTS");

        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(
        address stakingToken,
        address rewardToken,
        uint256 rewardAmount,
        uint256 rewardsDuration
    ) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
            stakingToken
        ];
        require(rewardToken != address(0) && stakingToken != address(0), "IA");
        require(rewardToken != stakingToken, "IA");
        require(info.stakingRewards == address(0), "AD");
        require(rewardAmount > 0, "ZR");
        address stakingRewardContract = address(
            new StakingRewards{
                salt: keccak256(
                    abi.encodePacked(
                        stakingToken,
                        rewardToken,
                        rewardAmount,
                        rewardsDuration
                    )
                )
            }(msg.sender, address(this), rewardToken, stakingToken)
        );

        info.stakingRewards = stakingRewardContract;
        info.rewardToken = rewardToken;
        info.rewardAmount = rewardAmount;
        info.duration = rewardsDuration;
        stakingTokens.push(stakingToken);
        emit Deployed(
            stakingRewardContract,
            stakingToken,
            rewardToken,
            rewardAmount,
            rewardsDuration
        );
    }

    function update(
        address stakingToken,
        uint256 rewardAmount,
        uint256 rewardsDuration
    ) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
            stakingToken
        ];
        require(info.stakingRewards != address(0), "UND");

        info.rewardAmount = rewardAmount;
        info.duration = rewardsDuration;

        emit Updated(info.stakingRewards, rewardAmount, rewardsDuration);
    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingTokens.length > 0, "CBD");
        for (uint256 i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, "NNR");

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[
            stakingToken
        ];
        require(info.stakingRewards != address(0), "NND");

        if (info.rewardAmount > 0 && info.duration > 0) {
            uint256 rewardAmount = info.rewardAmount;
            uint256 duration = info.duration;
            info.rewardAmount = 0;
            info.duration = 0;

            require(
                IERC20(info.rewardToken).transfer(
                    info.stakingRewards,
                    rewardAmount
                ),
                "TF"
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(
                rewardAmount,
                duration
            );
        }
    }

    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
