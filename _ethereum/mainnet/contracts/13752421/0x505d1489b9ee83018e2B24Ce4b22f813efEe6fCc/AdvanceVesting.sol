// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./BaseVesting.sol";

contract AdvanceVesting is BaseVesting {
    using SafeMath for uint256;

    uint256 public immutable cliffDuration;
    uint256 public immutable tgePercentage;
    uint256 public immutable firstRelease;

    constructor(
        address signer_,
        address token_,
        uint256 startDate_,
        uint256 cliffDuration_,
        uint256 vestingDuration_,
        uint256 tgePercentage_,
        uint256 totalAllocatedAmount_
    )
        BaseVesting(
            signer_,
            token_,
            startDate_,
            vestingDuration_,
            totalAllocatedAmount_
        )
    {
        require(
            tgePercentage_ < PERCENTAGE,
            "The tgePercentage cannot be greater than 100"
        );
        cliffDuration = cliffDuration_;
        uint256 firstReleaseTimestamp = startDate_.add(cliffDuration_);
        firstRelease = firstReleaseTimestamp;
        vestingTimeEnd = firstReleaseTimestamp.add(vestingDuration_);
        tgePercentage = tgePercentage_;
        uint256 remainingPercentage = PERCENTAGE.sub(tgePercentage_);
        uint256 periods = vestingDuration_.div(PERIOD);
        everyDayReleasePercentage = remainingPercentage.div(periods);
    }

    function _calculateAvailablePercentage()
        internal
        view
        override
        returns (uint256)
    {
        uint256 currentTimeStamp = block.timestamp;
        if (currentTimeStamp < firstRelease) {
            return tgePercentage;
        } else if (currentTimeStamp < vestingTimeEnd) {
            uint256 noOfDays = currentTimeStamp.sub(firstRelease).div(PERIOD);
            uint256 currentUnlockedPercentage = noOfDays.mul(
                everyDayReleasePercentage
            );
            return tgePercentage.add(currentUnlockedPercentage);
        } else {
            return PERCENTAGE;
        }
    }
}
