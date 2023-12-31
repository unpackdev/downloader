// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RewardTemplateBase.sol";
import "./D4AErrors.sol";
import "./RewardStorage.sol";

contract LinearRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay period to be `n`, total reward to be `T`, then
     * `x = T / n * k`
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual override returns (uint256 rewardAmount) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];

        if (!rewardInfo.isProgressiveJackpot) {
            rewardAmount = rewardCheckpoint.totalReward / rewardCheckpoint.totalRound;
        } else {
            if (round >= rewardCheckpoint.startRound + rewardCheckpoint.totalRound) revert ExceedMaxMintableRound();

            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, round);
            // no active rounds before
            if (lastActiveRound == 0) {
                for (uint256 i; i < rewardCheckpointIndex; ++i) {
                    rewardAmount += rewardInfo.rewardCheckpoints[i].totalReward;
                }
                rewardAmount += rewardCheckpoint.totalReward / rewardCheckpoint.totalRound
                    * (round + 1 - rewardCheckpoint.startRound);
                return rewardAmount;
            }
            // round is at current reward checkpoint
            else if (lastActiveRound >= rewardCheckpoint.startRound) {
                rewardAmount = (round - lastActiveRound) * rewardCheckpoint.totalReward / rewardCheckpoint.totalRound;
                return rewardAmount;
            }
            // need to iterate all reward checkpoints from last active round to given round
            else {
                uint256 rewardCheckpointIndexOfLastActiveRound =
                    _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
                // calculate first checkpoint's reward amount
                RewardStorage.RewardCheckpoint storage lastActiveRoundRewardCheckpoint =
                    rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                rewardAmount = (
                    lastActiveRoundRewardCheckpoint.startRound + lastActiveRoundRewardCheckpoint.totalRound
                        - lastActiveRound - 1
                ) * lastActiveRoundRewardCheckpoint.totalReward / lastActiveRoundRewardCheckpoint.totalRound;
                for (; rewardCheckpointIndexOfLastActiveRound + 2 < rewardCheckpointIndex;) {
                    rewardAmount += rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound + 1].totalReward;
                    unchecked {
                        ++rewardCheckpointIndexOfLastActiveRound;
                    }
                }
                // calculate last checkpoint's reward amount
                rewardAmount += (round + 1 - rewardCheckpoint.startRound) * rewardCheckpoint.totalReward
                    / rewardCheckpoint.totalRound;
            }
        }
    }
}
