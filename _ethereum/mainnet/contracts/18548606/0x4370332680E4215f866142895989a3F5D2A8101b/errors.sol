//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// Token
    error Token_MultisigNotSet();
    error Token_WrongInputAddress();
    error Token_GovernanceAlreadySet();
    error Token_WrongInputUint();
    error Token_PresaleLimitReached();
    error Token_PresaleNotEnoughETH();
    error Token_StakingAlreadySet();

// Staking
    error Staking_IsPaused();
    error Staking_NotPaused();
    error Staking_WrongInputUint();
    error Staking_NoRewards();
    error Staking_NoDeposit();
    error Staking_WithdrawAmount();
    error Staking_NoSupplyForRewards();
    error Staking_TransferFailed(address _to, uint256 _amount);

// Locker
    error Locker_TransferFailed(address _to, uint256 _amount);
    error Locker_NoDepositForToken();
    error Locker_LockPeriodNotEnded();
    error Locker_WrongInputUint();
    error Locker_WrongInputAddress();
    error Locker_WrongLockDuration();