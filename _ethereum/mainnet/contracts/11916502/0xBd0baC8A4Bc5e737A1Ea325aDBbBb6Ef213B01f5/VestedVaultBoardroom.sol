// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Vault.sol";
import "./VaultBoardroom.sol";

contract VestedVaultBoardroom is VaultBoardroom {
    // For how much time should vesting take place.
    uint256 public vestFor;
    using SafeMath for uint256;

    /**
     * Event.
     */
    event VestingPeriodChanged(uint256 oldPeriod, uint256 period);

    /**
     * Constructor.
     */
    constructor(
        IERC20 token_,
        Vault vault_,
        uint256 vestFor_
    ) VaultBoardroom(token_, vault_) {
        vestFor = vestFor_;
    }

    /**
     * Views/Getters.
     */
    function earned(address director) internal override returns (uint256) {
        // Get the latest share per rewards i should get.
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        // Get the last share per rewards i have claimed.
        uint256 storedRPS = getLastSnapshotOf(director).rewardPerShare;

        uint256 prevEpochRewards = 0;
        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;

        // If last time rewards claimed were less than the latest epoch start time,
        // then we don't consider those rewards in further calculations and mark them
        // as pending.
        uint256 rewardEarnedCurrEpoch =
            (
                // If i am have unclaimed amount from the previous epoch
                // this `rewardEarnedCurrEpoch` should be set to 0
                // because i just moved `rewardEarnedCurrEpoch` to  `rewardPending`
                // in the _updateRewards func.
                // Else it should be kept as it is.
                directors[director].lastClaimedOn < latestFundingTime
                    ? 0
                    : directors[director].rewardEarnedCurrEpoch
            );

        // If storedRPS is 0, that means we are claiming rewards for the first time, hence we need
        // to check when we bonded and accordingly calculate the final rps.
        if (storedRPS == 0) {
            uint256 firstBondedSnapshotIndex =
                bondingHistory[director].snapshotIndexWhenFirstBonded;

            // This gets the last epoch at which i bonded.
            // if i bonded after 1st allocatin this would get rewardPerShare for 1st epoch.
            // If i bonded after 2nd allocation would get rewardPerShare for 2nd epoch.
            // and 0 if 1 bonded before 1st.
            storedRPS = boardHistory[firstBondedSnapshotIndex].rewardPerShare;
        }

        // If the allocations are more than 2 the basically there's a possiblity
        // that i have not claimed rewards for more than 1 epoch.
        // this could have condition that i've not claimed at all or i have claimed 1st epoch
        // but not 2nd and now claiming at 3rd(assuming curr epoch is 3rd)
        // also we need to make sure that here, this code runs only if
        // i've bonded before the latest epoch else, overfollow occurs in sub.
        if (boardHistory.length > 2) {
            if (
                bondingHistory[director].snapshotIndexWhenFirstBonded <
                latestSnapshotIndex() // this condition is added as overflow issues were occuring in case where i bond after latestEpoch.
            ) {
                // Get the last epohc's rewardPerShare.
                uint256 lastRPS =
                    boardHistory[latestSnapshotIndex().sub(1)].rewardPerShare;

                // Get the pending rewards from prev epochs.
                uint256 prevToPrevEpochsRewardEarned =
                    (
                        directors[director].lastClaimedOn < latestFundingTime
                            ? 0
                            : directors[director].rewardEarnedCurrEpoch
                    );

                // Get the reward i deserved from the last epoch to the last epoch i already claimed.
                // if they are same this should be 0.
                prevEpochRewards = vault
                    .balanceWithoutBonded(director)
                    .mul(lastRPS.sub(storedRPS))
                    .div(1e18);

                // add the penidng rewards if any.
                prevEpochRewards = prevEpochRewards.add(
                    prevToPrevEpochsRewardEarned
                );

                // mark this as pending as these are till the last epoch.
                directors[director].rewardPending = directors[director]
                    .rewardPending
                    .add(prevEpochRewards);
            }
        }

        // calculate the reward from latest epoch to epoch i claimed last.
        uint256 rewards =
            vault
                .balanceWithoutBonded(director)
                .mul(latestRPS.sub(storedRPS))
                .div(1e18)
                .add(rewardEarnedCurrEpoch);

        // now we have done a duplication caluclation, as in we have calcuated rewards from latest to lastClaimed
        // and from last to lastClaimed, i.e in case of 3 epoch lets say we claimed at 1.
        // so we've done 3 - 1 && 2 - 1. both of this contain (2 - 1). hece we subtract that duplication here.
        return rewards.sub(prevEpochRewards);
    }

    /**
     * Setters.
     */
    function setVestFor(uint256 period) public onlyOwner {
        emit VestingPeriodChanged(vestFor, period);
        vestFor = period;
    }

    function claimReward() public override directorExists returns (uint256) {
        _updateReward(msg.sender);

        // Get the current reward of the epoch.
        uint256 reward = directors[msg.sender].rewardEarnedCurrEpoch;
        if (reward <= 0) return 0;

        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;

        // If past the vesting period, then claim entire reward.
        if (block.timestamp >= latestFundingTime.add(vestFor)) {
            // If past latest funding time and vesting period then we claim entire 100%
            // reward from both previous and current and subtract the reward already claimed
            // in this epoch.
            reward = reward.add(directors[msg.sender].rewardPending).sub(
                directors[msg.sender].rewardClaimedCurrEpoch
            );

            // Reset the counters to 0 as we claimed all.
            directors[msg.sender].rewardEarnedCurrEpoch = 0;
            directors[msg.sender].rewardPending = 0;
            directors[msg.sender].rewardClaimedCurrEpoch = 0;
        }
        // If not past the vesting period, then claim reward as per linear vesting.
        else {
            uint256 timeSinceLastFunded =
                block.timestamp.sub(latestFundingTime);

            // Calculate reward to be given assuming msg.sender has not claimed in current
            // vesting cycle(8hr cycle).
            // NOTE: here we are multiplying by 1e3 to get precise decimal values.
            uint256 timelyRewardRatio =
                timeSinceLastFunded.mul(1e3).div(vestFor);

            if (directors[msg.sender].lastClaimedOn > latestFundingTime) {
                /*
                  And if msg.sender has claimed atleast once after the new vesting kicks in,
                  then we need to find the ratio for current time.

                  Let's say we want vesting to be for 10 seconds.
                  Then if we try to claim rewards at every 1 second then, we should get
                  1/10 of the rewards every second.
                  So for 1st second reward could be 1/10, for next also 1/10, we can convert
                  this to `(timeNext-timeOld)/timePeriod`.
                  For 1st second: (1-0)/10
                  For 2nd second: (2-1)/10
                  and so on.
                */
                uint256 timeSinceLastClaimed =
                    block.timestamp.sub(directors[msg.sender].lastClaimedOn);

                // NOTE: here we are multiplying by 1e3 to get precise decimal values.
                timelyRewardRatio = timeSinceLastClaimed.mul(1e3).div(vestFor);
            }

            // Update reward as per vesting.
            // NOTE: here we are nullyfying the multplication by 1e3 effect on the top.
            reward = timelyRewardRatio.mul(reward).div(1e3);

            // We add the reward claimed in this epoch to the variables.
            // We basically do this to maintain a log of original reward, so we use that in
            // vesting. and we use this counter to know how much from the original reward
            // we have claimed in the current claim under the vesting period. Otherwise it becomes
            // kind of curve vesting.
            directors[msg.sender].rewardClaimedCurrEpoch = (
                directors[msg.sender].rewardClaimedCurrEpoch.add(reward)
            );

            // If this is the first claim inside this vesting period, then we also
            // give away 100% of previous vesting period's pending rewards.
            if (directors[msg.sender].lastClaimedOn < latestFundingTime) {
                // HERE since this is the first claim we don't need to subtract claim reward in this epoch variable.
                reward = reward.add(directors[msg.sender].rewardPending);
                directors[msg.sender].rewardPending = 0;
            }
        }

        directors[msg.sender].lastClaimedOn = block.timestamp;

        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);

        return reward;
    }

    function claimAndReinvestReward() external virtual {
        // NOTE: amount has to be approved from the frontend.
        uint256 reward = claimReward();
        vault.bondFor(msg.sender, reward);
    }

    function updateReward(address director) public onlyVault {
        BondingSnapshot storage snapshot = bondingHistory[director];

        uint256 latestSnapshotIdx = latestSnapshotIndex();

        // This means, we are bonding for the first time.
        // Hence we save the timestamp when, we first bond and the
        // allocation index no. when we first bond.
        if (
            snapshot.firstBondedOn == 0 &&
            snapshot.snapshotIndexWhenFirstBonded == 0
        ) {
            snapshot.firstBondedOn = block.timestamp;
            // NOTE: probably will revert/throw error in case not allocated yet.
            snapshot.snapshotIndexWhenFirstBonded = latestSnapshotIdx;
        }

        // Update the rewards when bonding, unbonding and withdrawing.
        // In case of withdrawing 100%, unbond and withdraw will both call this.
        // However, the balanceWIthBonded would be 0 if we are unbonding, hence
        // ideally effect should be same as withdrawing.
        _updateReward(director);

        // This means withdrawing, Hence reset the counters.
        if (
            snapshot.firstBondedOn != 0 &&
            snapshot.snapshotIndexWhenFirstBonded != 0 &&
            vault.balanceOf(director) == 0
        ) {
            snapshot.firstBondedOn = 0;
            snapshot.snapshotIndexWhenFirstBonded = 0;
        }

        // Update the balance while recording this activity(whether withdraw of bond).
        uint256 balance = vault.balanceWithoutBonded(director);
        directorBalanceForEpoch[director][latestSnapshotIdx] = balance;
    }

    function _updateReward(address director) private {
        Boardseat storage seat = directors[director];

        // Set the default latest funding time to 0.
        // This represents that boardroom has not been allocated seigniorage yet.
        uint256 latestFundingTime = boardHistory[boardHistory.length - 1].time;

        // If rewards are updated before epoch start of the current,
        // then we mark claimable rewards as pending and set the
        // current earned rewards to 0.
        if (seat.lastClaimedOn < latestFundingTime) {
            // This basically set's current reward's which are not claimed as pending.
            // Since the user's last claim was before  the
            // latestFundingTime(epoch timestamp when allocated latest).
            seat.rewardPending = seat.rewardEarnedCurrEpoch.sub(
                seat.rewardClaimedCurrEpoch
            );
            // Reset the counters for the latest epoch.
            seat.rewardEarnedCurrEpoch = 0;
            seat.rewardClaimedCurrEpoch = 0;
        }

        // Generate fresh rewards for the current epoch.
        // This should only include reward for curr epoch.
        // If any remaining they are makred as pending.
        seat.rewardEarnedCurrEpoch = earned(director);
        // Update the last allocation index no. when claimed.
        seat.lastSnapshotIndex = latestSnapshotIndex();
    }
}
