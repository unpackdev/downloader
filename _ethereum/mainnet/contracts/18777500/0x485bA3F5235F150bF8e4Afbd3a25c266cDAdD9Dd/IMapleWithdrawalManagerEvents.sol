// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleWithdrawalManagerEvents {

    /**
     *  @dev   Emitted when the withdrawal configuration is updated.
     *  @param configId_         The identifier of the configuration.
     *  @param initialCycleId_   The identifier of the withdrawal cycle when the configuration takes effect.
     *  @param initialCycleTime_ The timestamp of the beginning of the withdrawal cycle when the configuration takes effect.
     *  @param cycleDuration_    The new duration of the withdrawal cycle.
     *  @param windowDuration_   The new duration of the withdrawal window.
     */
    event ConfigurationUpdated(
        uint256 indexed configId_,
        uint64 initialCycleId_,
        uint64 initialCycleTime_,
        uint64 cycleDuration_,
        uint64 windowDuration_
    );

    /**
     *  @dev   Emitted when a withdrawal request is cancelled.
     *  @param account_ Address of the account whose withdrawal request has been cancelled.
     */
    event WithdrawalCancelled(address indexed account_);

    /**
     *  @dev   Emitted when a withdrawal request is processed.
     *  @param account_          Address of the account processing their withdrawal request.
     *  @param sharesToRedeem_   Amount of shares that the account will redeem.
     *  @param assetsToWithdraw_ Amount of assets that will be withdrawn from the pool.
     */
    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);

    /**
     *  @dev   Emitted when a withdrawal request is updated.
     *  @param account_      Address of the account whose request has been updated.
     *  @param lockedShares_ Total amount of shares the account has locked.
     *  @param windowStart_  Time when the withdrawal window for the withdrawal request will begin.
     *  @param windowEnd_    Time when the withdrawal window for the withdrawal request will end.
     */
    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);

}
