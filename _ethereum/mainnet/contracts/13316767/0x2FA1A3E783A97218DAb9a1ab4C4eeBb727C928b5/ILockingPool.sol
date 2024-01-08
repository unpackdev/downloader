// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For pools that can be locked and unlocked in emergencies
 */
interface ILockingPool {
    /** @notice Log when deposits are locked */
    event AddLiquidityLocked();

    /** @notice Log when deposits are unlocked */
    event AddLiquidityUnlocked();

    /** @notice Log when withdrawals are locked */
    event RedeemLocked();

    /** @notice Log when withdrawals are unlocked */
    event RedeemUnlocked();

    /** @notice Lock deposits and withdrawals */
    function emergencyLock() external;

    /** @notice Unlock deposits and withdrawals */
    function emergencyUnlock() external;

    /** @notice Lock deposits */
    function emergencyLockAddLiquidity() external;

    /** @notice Unlock deposits */
    function emergencyUnlockAddLiquidity() external;

    /** @notice Lock withdrawals */
    function emergencyLockRedeem() external;

    /** @notice Unlock withdrawals */
    function emergencyUnlockRedeem() external;
}
