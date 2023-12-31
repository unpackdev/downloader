// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

interface IStaking {
    error StartIsGreaterThanFinish(uint _startAt, uint _finishAt);
    error AmountIsZero();
    error BalanceIsZero();
    error StakePoolClosed();
    error RewardPeriodNotFinished(uint _startAt, uint _finishAt);
    error RewardRateIsZero();
    error RewardRateIsMoreThanBalance(uint _balance, uint _rewardRate);
    error RewardsAlreadyNotified();
    error RewardPeriodFinished(uint _startAt, uint _finishAt);
    error TokensAreLockedUntilFinish(uint _finishAt);
    error MaxAmountSuperceeded(uint _amount);
    error AmountIsMoreThanBalance(uint _balance, uint _amount);
    error PercentageOutOfRange(uint _percentage);

    event TokensStaked(address _staker, uint _amount);
    event TokensWithdrawn(address _staker, uint _amount);
    event RewardsWithdrawn(address _staker, uint _amount);
    event EmergencyWithdraw(address _staker, uint _amount, uint _fee);
    event NotifiedRewards(uint _amount);
}
