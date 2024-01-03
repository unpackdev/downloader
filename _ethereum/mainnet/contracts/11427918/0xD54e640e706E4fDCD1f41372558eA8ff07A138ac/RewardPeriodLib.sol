//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./SafeMath.sol";

library RewardPeriodLib {
    using SafeMath for uint256;

    struct RewardPeriod {
        uint256 id;
        uint256 startPeriodTimestamp;
        uint256 endPeriodTimestamp;
        uint256 endRedeemablePeriodTimestamp;
        uint256 totalRewards;
        uint256 availableRewards;
        bool exists;
    }

    function create(
        RewardPeriod storage self,
        uint256 id,
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) internal {
        requireNotExists(self);
        require(block.timestamp <= startPeriodTimestamp, "START_TIMESTAMP_IS_INVALID");
        require(startPeriodTimestamp < endPeriodTimestamp, "REWARD_PERIOD_IS_INVALID");
        require(endPeriodTimestamp < endRedeemablePeriodTimestamp, "END_REDEEM_PERIOD_IS_INVALID");
        require(availableRewards > 0, "REWARDS_MUST_BE_GT_ZERO");
        self.id = id;
        self.startPeriodTimestamp = startPeriodTimestamp;
        self.endPeriodTimestamp = endPeriodTimestamp;
        self.endRedeemablePeriodTimestamp = endRedeemablePeriodTimestamp;
        self.availableRewards = availableRewards;
        self.totalRewards = availableRewards;
        self.exists = true;
    }

    function isInProgress(RewardPeriod storage self) internal view returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return
            self.exists &&
            self.startPeriodTimestamp <= currentTimestamp &&
            currentTimestamp <= self.endPeriodTimestamp;
    }

    function isInRedemption(RewardPeriod storage self) internal view returns (bool) {
        return isFinished(self) && self.endRedeemablePeriodTimestamp > block.timestamp;
    }

    function isFinished(RewardPeriod storage self) internal view returns (bool) {
        return self.exists && self.endPeriodTimestamp < block.timestamp;
    }

    function isPending(RewardPeriod storage self) internal view returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return self.exists && self.startPeriodTimestamp > currentTimestamp;
    }

    /**
        @notice Checks whether the current reward period exists or not.
        @dev It throws a require error if the reward period already exists.
        @param self the current reward period.
     */
    function requireNotExists(RewardPeriod storage self) internal view {
        require(!self.exists, "REWARD_PERIOD_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current reward period exists or not.
        @dev It throws a require error if the current reward period doesn't exist.
        @param self the current reward period.
     */
    function requireExists(RewardPeriod storage self) internal view {
        require(self.exists, "REWARD_PERIOD_NOT_EXISTS");
    }

    function endsBefore(RewardPeriod storage self, uint256 startPeriodTimestamp)
        internal
        view
        returns (bool)
    {
        return self.exists && self.endPeriodTimestamp < startPeriodTimestamp;
    }

    function notifyRewardsSent(RewardPeriod storage self, uint256 amount) internal returns (bool) {
        self.availableRewards = self.availableRewards.sub(amount);
    }

    /**
        @notice It removes a current reward period.
        @param self the current reward period to remove.
     */
    function remove(RewardPeriod storage self) internal {
        requireExists(self);
        self.id = 0;
        self.startPeriodTimestamp = 0;
        self.endPeriodTimestamp = 0;
        self.endRedeemablePeriodTimestamp = 0;
        self.totalRewards = 0;
        self.availableRewards = 0;
        self.exists = false;
    }
}
