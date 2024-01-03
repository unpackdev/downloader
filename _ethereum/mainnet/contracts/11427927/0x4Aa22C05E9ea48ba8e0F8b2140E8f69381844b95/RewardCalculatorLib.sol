//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

library RewardCalculatorLib {
    uint256 private constant MAX_PERCENTAGE = 10000;

    struct RewardCalculator {
        uint256 percentage; // 1000 => 10% (10 * 100)
        bool paused;
        bool exists;
    }

    function create(RewardCalculator storage self, uint256 percentage) internal {
        requireNotExists(self);
        require(percentage <= MAX_PERCENTAGE, "PERCENTAGE_MUST_BE_LT_MAX");
        self.percentage = percentage;
        self.exists = true;
    }

    /**
        @notice It updates the current reward calculator.
        @param self the current reward calculator.
        @param newPercentage the new percentage to set in the reward calculator.
     */
    function update(RewardCalculator storage self, uint256 newPercentage)
        internal
        returns (uint256 oldPercentage)
    {
        requireExists(self);
        require(self.percentage != newPercentage, "NEW_PERCENTAGE_REQUIRED");
        require(newPercentage < MAX_PERCENTAGE, "PERCENTAGE_MUST_BE_LT_MAX");
        oldPercentage = self.percentage;
        self.percentage = newPercentage;
    }

    function pause(RewardCalculator storage self) internal {
        requireExists(self);
        require(!self.paused, "CALCULATOR_ALREADY_PAUSED");
        self.paused = true;
    }

    function unpause(RewardCalculator storage self) internal {
        requireExists(self);
        require(self.paused, "CALCULATOR_NOT_PAUSED");
        self.paused = false;
    }

    function getPercentage(RewardCalculator storage self) internal view returns (uint256) {
        return self.exists && !self.paused ? self.percentage : 0;
    }

    /**
        @notice Checks whether the current reward calculator exists or not.
        @dev It throws a require error if the reward calculator already exists.
        @param self the current reward calculator.
     */
    function requireNotExists(RewardCalculator storage self) internal view {
        require(!self.exists, "REWARD_CALC_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current reward calculator exists or not.
        @dev It throws a require error if the current reward calculator doesn't exist.
        @param self the current reward calculator.
     */
    function requireExists(RewardCalculator storage self) internal view {
        require(self.exists, "REWARD_CALC_NOT_EXISTS");
    }

    /**
        @notice It removes a current reward calculator.
        @param self the current reward calculator to remove.
     */
    function remove(RewardCalculator storage self) internal {
        requireExists(self);
        self.percentage = 0;
        self.exists = false;
    }
}
