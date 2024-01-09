pragma solidity 0.8.10;

import "./EpochHelpers.sol";
import "./SafeMath.sol";

contract RewardHelpers is EpochHelpers {
    using SafeMath for uint256;

    uint256 public lastEpochUpdate = 1;

    // Function to calculate rewards over a year (26 epochs)
    function returnCurrentAPY() public view returns (uint256) {
        uint256 currentEpoch = returnCurrentEpoch();
        uint256 totalReward;
        // Checks if there is epochs that have rewards that aren't equal to 600
        if (currentEpoch < 10) {
            // The amount of epochs where the rewards aren't equal to 600
            uint256 epochLoops = uint256(10).sub(currentEpoch);
            // Iterate over each epoch to grab rewards for each of those epochs
            for (
                uint256 i = currentEpoch;
                i < epochLoops.add(currentEpoch);
                i++
            ) {
                uint256 epochReward = returnTotalRewardForEpoch(i);
                totalReward = totalReward.add(epochReward);
            }
            // Add in $600 rewards for every epoch where the rewards are equal to 600
            totalReward = totalReward.add(
                uint256(600 ether).mul(uint256(26).sub(epochLoops))
            );
        } else {
            // Every epoch has rewards equal to $600
            totalReward = uint256(600 ether).mul(26);
        }

        // The overall total for all users
        uint256 overallEpochTotal = _returnEpochAmountIncludingCurrentTotal(
            epochAmounts[lastEpochUpdate]
        );

        // If 0 for the epoch total, set it to 1
        if (overallEpochTotal == 0) {
            overallEpochTotal = 1 ether;
        }
        uint256 totalAPY = totalReward.mul(1 ether).div(overallEpochTotal);

        return totalAPY;
    }

    function _returnClaimSecondsForPulledLiquidity(
        uint256 lastClaimedTimestamp,
        uint256 currentEpoch
    ) public view returns (uint256) {
        uint256 lastClaimedEpoch = _returnEpochToTimestamp(
            lastClaimedTimestamp
        );

        uint256 claimSecondsForPulledLiquidity;

        if (lastClaimedEpoch == currentEpoch) {
            // If they've claimed in this epoch, they should only be able to claim from when they last claimed to now
            return
                claimSecondsForPulledLiquidity = block.timestamp.sub(
                    lastClaimedTimestamp
                );
        } else {
            // If they haven't claimed in this epoch, then the claim seconds are from when the epoch start to now
            uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);

            return epochLength.sub(secondsToEpochEnd);
        }
    }

    // Returns the seconds that a user can claim rewards for in any given epoch
    function _returnEpochClaimSeconds(
        uint256 epoch,
        uint256 currentEpoch,
        uint256 lastEpochClaimed,
        uint256 lastClaimedTimestamp
    ) public view returns (uint256) {
        // If the given epoch is the current epoch
        if (epoch == currentEpoch) {
            // If the user claimed rewards in this epoch, the claim seconds would be the block.timestamp - lastClaimedtimestamp
            if (lastEpochClaimed == currentEpoch) {
                return block.timestamp.sub(lastClaimedTimestamp);
            }
            // If the user hasn't claimed in this epoch, the claim seconds is the timestamp - startOfEpoch
            uint256 givenEpochStartTime = returnGivenEpochStartTime(epoch);

            return block.timestamp.sub(givenEpochStartTime);
            // If the user last claimed in the given epoch, but it isn't the current epoch
        } else if (lastEpochClaimed == epoch) {
            // The claim seconds is the end of the given epoch - the lastClaimed timestmap
            uint256 givenEpochEndTime = returnGivenEpochEndTime(epoch);
            // If they've already claimed rewards in this epoch, calculate their claim seconds as the difference between that timestamp and now.

            return givenEpochEndTime.sub(lastClaimedTimestamp);
        }

        // Return full length of epoch if it isn't the current epoch and the user hasn't previously claimed in this epoch.
        return epochLength;
    }

    function _returnRewardAmount(
        uint256 usersInvestmentTotal,
        uint256 overallInvestmentTotal,
        uint256 secondsToClaim,
        uint256 totalReward
    ) public view returns (uint256) {
        // Calculate the total epoch reward share as: totalReward * usersInvestmentTotal / overallEpochTotal
        uint256 totalEpochRewardShare = totalReward
            .mul(usersInvestmentTotal)
            .div(overallInvestmentTotal);

        // Calculate the proportional reward share as totalEpochRewardShare * secondsToClaim / epochLength
        uint256 proportionalRewardShare = totalEpochRewardShare
            .mul(secondsToClaim)
            .div(epochLength);
        // totalReward * (usersInvestmentTotal / overallEpochTotal) * (secondsToClaim / epochLength)

        return proportionalRewardShare;
    }

    function _calculateRewardShareForEpoch(
        uint256 epoch,
        uint256 currentEpoch,
        uint256 lastEpochClaimed,
        uint256 lastClaimedTimestamp,
        uint256 usersInvestmentTotal,
        uint256 overallInvestmentTotal
    ) internal view returns (uint256) {
        // If the last claimed timestamp is the same epoch as the epoch passed in
        uint256 claimSeconds = _returnEpochClaimSeconds(
            epoch,
            currentEpoch,
            lastEpochClaimed,
            lastClaimedTimestamp
        );

        // Total rewards in the given epoch
        uint256 totalEpochRewards = returnTotalRewardForEpoch(epoch);

        return
            _returnRewardAmount(
                usersInvestmentTotal,
                overallInvestmentTotal,
                claimSeconds,
                totalEpochRewards
            );
    }
}
