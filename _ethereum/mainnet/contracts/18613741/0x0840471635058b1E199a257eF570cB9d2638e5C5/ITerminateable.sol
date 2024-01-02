// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITerminateable {
    /**
     * @notice Reverts if termination time is before lock start.
     * @param terminationFrom Timestamp from which tokens will be terminated.
     * @param lockFrom Timestamp from which tokens will be locked.
    */
    error TerminationTimeMustBeAfterLockStart(uint256 terminationFrom, uint256 lockFrom);

    /**
     * @notice Emits when timelock is terminated.
     * @param receiver Address of the receiver.
     * @param terminationFrom Timestamp from which tokens will be terminated.
     */
    event TimelockTerminated(address indexed receiver, uint256 terminationFrom);

    /**
     * @notice Emits when timelock is determinated.
     * @param receiver Address of the receiver.
     */
    event TimelockDeterminated(address indexed receiver);

    /**
     * @notice Terminates timelock for the receiver.
     * @param receiver Address of the receiver.
     * @param terminationFrom Timestamp from which tokens will be terminated.
     */
    function terminate(address receiver, uint256 terminationFrom) external;

    /**
     * @notice Determinates timelock for the receiver.
     * @param receiver Address of the receiver.
     */
    function determinate(address receiver) external;
}