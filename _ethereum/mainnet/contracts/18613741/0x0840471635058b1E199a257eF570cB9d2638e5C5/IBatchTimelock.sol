// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBatchTimelock {
    /**
     * @notice Reverts if amount exceeds vesting allowance.
     * @param amount Amount of tokens to be claimed.
     * @param claimable Amount of tokens that can be claimed.
     */
    error AmountExceedsWithdrawableAllowance(uint256 amount, uint256 claimable);

    /**
     * @notice Reverts if cliff period has not ended.
     */
    error CliffPeriodNotEnded(uint256 timeNow, uint256 cliffEndsAt);

    /**
     * @notice Reverts if vesting period has not started.
     */
    error ZeroAllocation();

    /**
     * @notice Reverts if empty receivers array is passed.
     */
    error EmptyReceiversArray();

    /**
     * @notice Reverts if invalid receiver address is passed.
     */
    error InvalidReceiverAddress();

    /**
     * @notice Reverts if invalid timelock amount is passed.
     */
    error InvalidTimelockAmount();

    /**
     * @notice Reverts if receiver already has a timelock.
     * @param receiver Address of the receiver.
     */
    error ReceiverAlreadyHasATimelock(address receiver);

    /**
     * @notice Reverts if zero claim amount is passed.
    */
    error ZeroClaimAmount();

    /**
     * @notice Reverts if token transfer failed.
     * @param vestingPool Address of the token pool.
     * @param receiver Address of the receiver.
     * @param amount Amount of tokens transferred.
    */
    error TokenTransferFailed(address vestingPool, address receiver, uint256 amount);

    /**
     * @dev Reverts if the caller is not a termination admin.
     */
    error CallerIsNotATerminationAdmin();

    /**
     * @dev Reverts if the caller is not the timelock creator.
     */
    error CallerIsNotATimelockCreator();

    /**
     * @notice Token receiver struct that is used for adding _timelocks for timelock.
     * @param receiver Address of the receiver.
     * @param totalAmount Total amount of tokens to be vested.
     * @param timelockFrom Timestamp from which the timelock will start.
     * @param cliffDuration Cliff time in months (6 months default).
     * @param vestingDuration Vesting duration in months (18/24 months).
     */
    struct Receiver {
        address receiver;
        uint256 totalAmount;
        uint256 timelockFrom;
        uint256 cliffDuration;
        uint256 vestingDuration;
    }

    /**
     * @notice Timelock struct that is used for vesting.
     * @param receiver Address of the receiver.
     * @param totalAmount Total amount of tokens to be vested.
     * @param releasedAmount Amount of tokens released.
     * @param lockFrom Timestamp from which tokens will start to vest.
     * @param cliffDuration Cliff time in months (6 months default).
     * @param vestingDuration Vesting duration in months (18/24 months).
     * @param terminationFrom Timestamp from which tokens will be terminated.
     * @param isTerminated Flag that indicates if timelock is terminated.
     */
    struct Timelock {
        address receiver;
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 timelockFrom;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 terminationFrom;
        bool isTerminated;
    }

    /**
     * @notice Emits when timelock is created.
     * @param receiver Address of the receiver.
     * @param totalAmount Total amount of tokens to be vested.
     * @param cliffDuration Cliff time in seconds (6 months default).
     * @param vestingDuration Vesting duration in seconds (18/24 months).
     */
    event TimelockCreated(address indexed receiver, uint256 totalAmount, uint256 timelockFrom, uint256 cliffDuration, uint256 vestingDuration);

    /**
     * @notice Emits when tokens are claimed.
     * @param receiver Address of the claimer.
     * @param amount Amount of tokens claimed.
     */
    event TokensClaimed(address indexed receiver, uint256 amount);

    /**
     * @notice Creates timelock for token receivers in a batch mode.
     * @param receivers Array of receivers.
     */
    function addTimelockBatch(Receiver[] memory receivers) external;

    /**
     * @notice Creates timelock for token receiver.
     * @param receiver Address of the receiver.
     * @param totalAmount Total amount of tokens to be vested.
     * @param timelockFrom Timestamp from which the timelock will start.
     * @param cliffDuration Cliff time in seconds (6 months default).
     * @param vestingDuration Vesting duration in seconds (18/24 months).
    */
    function addTimelock(address receiver, uint256 totalAmount, uint256 timelockFrom, uint256 cliffDuration, uint256 vestingDuration) external;

    /**
     * @notice Claims tokens for the receiver.
     * @param amount Amount of tokens to be claimed.
     */
    function claim(uint256 amount) external;

    /**
     * @notice Sets vesting pool address.
     * @param vestingPool Address of the vestingPool.
     */
    function setVestingPool(address vestingPool) external;

    /**
     * @notice Returns the timelock data.
     * @param receiver Address of the receiver.
     */
    function getTimelock(address receiver) external view returns (Timelock memory);

    /**
     * @notice Returns the amount of tokens that are currently allowed for claim.
     * @param receiver Address of the receiver.
     */
    function getClaimableBalance(address receiver) external view returns (uint256);

    /**
     * @notice Returns the array of timelock receivers.
     * @param offset Offset from which receivers will be returned.
     * @param limit Limit of receivers to be returned.
     */
    function getTimelockReceivers(uint256 offset, uint256 limit) external view returns (address[] memory);

    /**
     * @notice Returns the amount of timelock receivers.
     */
    function getTimelockReceiversAmount() external view returns (uint256);
}