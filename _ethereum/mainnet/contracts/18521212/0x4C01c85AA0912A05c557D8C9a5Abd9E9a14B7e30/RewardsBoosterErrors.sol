// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 RewardsBoosterErrors library
 * @author Asymetrix Protocol Inc Team
 * @notice A library with errors for rewards booster contracts.
 */
library RewardsBoosterErrors {
    error WrongLockDurtionSettingsNumber();
    error WrongBalancerPoolTokensNumber();
    error WrongLockDurtionSettings();
    error TooSmallBoostThreshold();
    error NoEmptySlotsInThisPool();
    error InvalidStakeArguments();
    error WrongValidityDuration();
    error TooBigBoostThreshold();
    error TooMuchLocksCreated();
    error StakeTokenWithdraw();
    error LockIsNotFinished();
    error WrongLockDurtion();
    error NotExistingPool();
    error NotExistingLock();
    error LengthsMismatch();
    error NotContract();
    error ZeroAddress();
    error ZeroAmount();
    error StalePrice();
    error WrongTick();
    error WrongTokensRatio();
    error WrongMaxTokenDominance();
    error StubMethod();
}
