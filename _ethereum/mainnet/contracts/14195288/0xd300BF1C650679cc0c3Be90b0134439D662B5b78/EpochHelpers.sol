pragma solidity 0.8.10;

import "./SafeMath.sol";

contract EpochHelpers {
    using SafeMath for uint256;

    struct EpochInvestmentDetails {
        // Sum of all normalised epoch values
        uint256 shareTotal;
        // Sum of all liquidity amounts from the previous epochs
        uint256 allPrevInvestmentTotals;
        // Sum of all liquidity amounts, excluding amounts from the current epoch. This is so the share amounts aren't included twice.
        uint256 currentInvestmentTotal;
        // Boolean to hold whether liquidity was withdrawn in this epoch
        bool withdrewLiquidity;
    }

    uint256 internal epochStart;
    uint256 internal epochLength = 14 days;

    // For storing overall details
    mapping(uint256 => EpochInvestmentDetails) public epochAmounts;

    function _returnEpochAmountIncludingShare(
        EpochInvestmentDetails memory epochInvestmentDetails
    ) internal pure returns (uint256) {
        return
            epochInvestmentDetails.allPrevInvestmentTotals.add(
                epochInvestmentDetails.shareTotal
            );
    }

    function _returnEpochAmountIncludingCurrentTotal(
        EpochInvestmentDetails memory epochInvestmentDetails
    ) internal view returns (uint256) {
        return
            epochInvestmentDetails.allPrevInvestmentTotals.add(
                epochInvestmentDetails.currentInvestmentTotal
            );
    }

    function returnGivenEpochEndTime(uint256 epoch)
        public
        view
        returns (uint256)
    {
        return epochStart.add(epochLength.mul(epoch));
    }

    function returnGivenEpochStartTime(uint256 epoch)
        public
        view
        returns (uint256)
    {
        return epochStart.add(epochLength.mul(epoch.sub(1)));
    }

    function returnCurrentEpoch() public view returns (uint256) {
        return block.timestamp.sub(epochStart).div(epochLength).add(1);
    }

    function _returnEpochToTimestamp(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        // ((timestamp - epochStart) / epochLength) + 1;
        // Add 1 to the end because it will round down the remainder value
        return timestamp.sub(epochStart).div(epochLength).add(1);
    }

    function _getSecondsToEpochEnd(uint256 currentEpoch)
        public
        view
        returns (uint256)
    {
        // Add to the epoch start date the duration of the current epoch + 1 * the epoch length.
        // Then subtract the block.timestamp to get the duration to the next epoch
        // epochStart + (currentEpoch * epochLength) - block.timestamp
        uint256 epochEndTime = epochStart.add(currentEpoch.mul(epochLength));
        // Prevent a math underflow by returning 0 if the given epoch is complete
        if (epochEndTime < block.timestamp) {
            return 0;
        } else {
            return epochEndTime.sub(block.timestamp);
        }
    }

    // The actual epoch rewards are 750 per week. But that shouldn't affect this
    // If claiming from an epoch that is in-progress you would get a proportion anyway
    function returnTotalRewardForEpoch(uint256 epoch)
        public
        pure
        returns (uint256)
    {
        // If the epoch is greater than or equal to 10 return 600 as the reward. This prevents a safemath underflow
        if (epoch >= 10) {
            return 600 ether;
        }
        // 1500 - (epoch * 100)
        uint256 rewardTotal = uint256(1500 ether).sub(
            uint256(100 ether).mul(epoch.sub(1))
        );

        return rewardTotal;
    }

    function returnIfInFirstDayOfEpoch(uint256 currentEpoch)
        public
        view
        returns (bool)
    {
        uint256 secondsToEpochEnd = _getSecondsToEpochEnd(currentEpoch);
        // The subtraction overflows the the currentEpoch value passed in isn't the current epoch and a future epoch
        uint256 secondsToEpochStart = epochLength.sub(secondsToEpochEnd);

        // If the seconds to epoch start is less than 1 day then true
        if (secondsToEpochStart <= 1 days) {
            return true;
        } else {
            return false;
        }
    }
}
