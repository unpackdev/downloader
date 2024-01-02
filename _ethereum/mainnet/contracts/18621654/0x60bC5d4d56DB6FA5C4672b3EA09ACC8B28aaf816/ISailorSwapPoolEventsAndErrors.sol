// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface ISailorSwapPoolEventsAndErrors {
    event Deposit(address depositor, uint256[] ids);
    event Withdraw(address withdrawer, uint256[] ids);
    event EarlyWithdraw(address withdrawer, uint256[] ids);
    event Swap(address user, uint256[] depositIDs, uint256[] withdrawIDs);
    event Claimed(address user, uint256 claimed);

    error NoStake();
    error NotEnoughStake();
    error NotValidCollection();
    error NotEnoughForSwap();
    error FeeRequired();
    error RefundFailed();
    error TransferFeesFailed();
    error TransferFailed();
    error SlippageTooHigh();
    error PoolFactoryPaused();
}
