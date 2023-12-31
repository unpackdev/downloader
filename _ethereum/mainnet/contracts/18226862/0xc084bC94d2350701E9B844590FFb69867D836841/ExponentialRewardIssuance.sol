// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./FixedPointMathLib.sol";

import "./D4AErrors.sol";
import "./RewardStorage.sol";
import "./RewardTemplateBase.sol";

contract ExponentialRewardIssuance is RewardTemplateBase {
    /**
     * @dev denote decay factor to be `k`, reward per round to be x,
     * decay round to be `n`, total reward to be `T`, then
     * `(x / k ^ 0) + (x / k ^ 1) + ... + (x / k ^ (n - 1)) = T`
     * `x = T * (1 - 1 / k) / (1 - 1 / k ^ n)`
     */
    function getRoundReward(bytes32 daoId, uint256 round) public view virtual override returns (uint256 rewardAmount) {
        RewardStorage.RewardInfo storage rewardInfo = RewardStorage.layout().rewardInfos[daoId];
        uint256 rewardCheckpointIndex = _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, round);
        RewardStorage.RewardCheckpoint storage rewardCheckpoint = rewardInfo.rewardCheckpoints[rewardCheckpointIndex];

        if (!rewardInfo.isProgressiveJackpot) {
            // kn is 27 decimal for now
            uint256 oneOverKn =
                MathMate.rpow(1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, rewardCheckpoint.totalRound, 1e27);
            uint256 beginReward = rewardCheckpoint.totalReward
                * (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor) / (1e27 - oneOverKn);
            rewardAmount = beginReward
                * MathMate.rpow(
                    1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor,
                    _getBelowRoundCount(rewardCheckpoint.activeRounds, round),
                    1e27
                ) / 1e27;
            return rewardAmount;
        } else {
            if (round >= rewardCheckpoint.startRound + rewardCheckpoint.totalRound) revert ExceedMaxMintableRound();

            uint256 lastActiveRound = _getLastActiveRound(rewardInfo, round);
            // no active rounds before
            if (lastActiveRound == 0) {
                for (uint256 i; i < rewardCheckpointIndex; ++i) {
                    rewardAmount += rewardInfo.rewardCheckpoints[i].totalReward;
                }
                // calculate last checkpoint's reward amount
                // kn is 27 decimal for now
                uint256 oneOverKn =
                    MathMate.rpow(1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, rewardCheckpoint.totalRound, 1e27);
                uint256 beginReward = rewardCheckpoint.totalReward
                    * (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor) / (1e27 - oneOverKn);
                // denote period number to be `n`, begin claimable reward to be `x`, then
                // `x + x / k + ... + x / k ^ (n - 1) = x * (1 - (1 / k) ^ n) / (1 - 1 / k)`
                oneOverKn = MathMate.rpow(
                    1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, round + 1 - rewardCheckpoint.startRound, 1e27
                );
                rewardAmount +=
                    beginReward * (1e27 - oneOverKn) / (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor);
                return rewardAmount;
            }
            // round is at current reward checkpoint
            else if (lastActiveRound >= rewardCheckpoint.startRound) {
                uint256 oneOverKn =
                    MathMate.rpow(1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, rewardCheckpoint.totalRound, 1e27);
                uint256 beginReward = rewardCheckpoint.totalReward
                    * (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor) / (1e27 - oneOverKn);
                uint256 lastActiveRoundReward = beginReward
                    * MathMate.rpow(
                        1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor,
                        lastActiveRound - rewardCheckpoint.startRound,
                        1e27
                    ) / 1e27;
                // rewardAmount = x * (1 - 1 / k ^ n) / (k - 1)
                oneOverKn =
                    MathMate.rpow(1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, round - lastActiveRound, 1e27);
                return lastActiveRoundReward * (1e27 - oneOverKn)
                    / (1e27 * rewardInfo.rewardDecayFactor / BASIS_POINT - 1e27);
            }
            // need to iterate over all reward checkpoints from last active round to given round
            else {
                uint256 rewardCheckpointIndexOfLastActiveRound =
                    _getRewardCheckpointIndexByRound(rewardInfo.rewardCheckpoints, lastActiveRound);
                {
                    // calculate first checkpoint's reward amount
                    RewardStorage.RewardCheckpoint storage lastActiveRoundRewardCheckpoint =
                        rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound];
                    // oneOverKn is 27 decimal for now
                    uint256 oneOverKn = MathMate.rpow(
                        1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor,
                        lastActiveRoundRewardCheckpoint.totalRound,
                        1e27
                    );
                    // reward amount of the first period at last active round's checkpoint
                    uint256 beginReward = lastActiveRoundRewardCheckpoint.totalReward
                        * (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor) / (1e27 - oneOverKn);
                    oneOverKn = MathMate.rpow(
                        1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor,
                        lastActiveRound + 1 - lastActiveRoundRewardCheckpoint.startRound,
                        1e27
                    );
                    rewardAmount = lastActiveRoundRewardCheckpoint.totalReward
                        - beginReward * (1e27 - oneOverKn) / (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor);
                }
                // use `rewardCheckpointIndexOfLastActiveRound` to iterate all reward checkpoints but the fist one and
                // the last one, here use `rewardCheckpointIndexOfLastActiveRound + 2 < rewardCheckpointIndex` instead
                // of `rewardCheckpointIndexOfLastActiveRound + 1 < rewardCheckpointIndex - 1` to avoid underflow
                for (; rewardCheckpointIndexOfLastActiveRound + 2 < rewardCheckpointIndex;) {
                    rewardAmount += rewardInfo.rewardCheckpoints[rewardCheckpointIndexOfLastActiveRound + 1].totalReward;
                    unchecked {
                        ++rewardCheckpointIndexOfLastActiveRound;
                    }
                }
                {
                    // calculate last checkpoint's reward amount
                    // kn is 27 decimal for now
                    uint256 oneOverKn = MathMate.rpow(
                        1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, rewardCheckpoint.totalRound, 1e27
                    );
                    uint256 beginReward = rewardCheckpoint.totalReward
                        * (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor) / (1e27 - oneOverKn);
                    // denote period number to be `n`, begin claimable reward to be `x`, then
                    // `x + x / k + ... + x / k ^ (n - 1) = x * (k ^ n - 1) / (k ^ n - k ^ (n - 1)`
                    oneOverKn = MathMate.rpow(
                        1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor, round + 1 - rewardCheckpoint.startRound, 1e27
                    );
                    rewardAmount +=
                        beginReward * (1e27 - oneOverKn) / (1e27 - 1e27 * BASIS_POINT / rewardInfo.rewardDecayFactor);
                }
            }
        }
    }
}
