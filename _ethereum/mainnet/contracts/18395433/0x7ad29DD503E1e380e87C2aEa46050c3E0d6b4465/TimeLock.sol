// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

/**
 * @title TimeLock
 * @dev This contract provides a time lock mechanism. Functions with the `timeLocked` modifier
 * can only be called after either `startTime` or `lastTime` has expired.
 */
contract TimeLock {

    uint256 public constant MAX_LOCK = type(uint256).max;

    uint256 public startTime;
    uint256 public lastTime;
    uint256 public startLock;
    uint256 public lastLock;

    error ErrorTimeLocked(uint256 remaining);

    /**
     * @dev Initializes the contract setting the `startLock` and `lastLock` state variables.
     * @param _startLock The max time after `startTime` when function can be called.
     * @param _lastLock The max time after `lastTime` when function can be called.
     */
    constructor(uint256 _startLock, uint256 _lastLock) {
        startLock = _startLock;
        lastLock = _lastLock;
    }

    /**
     * @dev Modifier to make a function callable only after the lock has expired.
     */
    modifier timeLocked() {
        uint256 t = timeLockLeft();
        if (t > 0) revert ErrorTimeLocked(t);
        _;
    }

    /**
     * @dev Set the last time and initialize start time if not set.
     */
    function timeLock() internal {
        if (timeLockExpired()) return;
        lastTime = block.timestamp;
        if (startTime == 0) startTime = lastTime;
    }

    /**
     * @dev Reset the start and last time to zero.
     */
    function resetTimeLock() internal {
        startTime = lastTime = 0;
    }

    /**
     * @dev Check if the time lock is active (not expired).
     * @return Time remaining if lock is active, false otherwise.
     */
    function timeLockLeft() internal view returns (uint256) {
        if (startTime == 0) return MAX_LOCK;
        uint256 cancelTime = _cancelTime(startLock, lastLock);
        return (block.timestamp < cancelTime) ? cancelTime - block.timestamp : 0;
    }

    /**
     * @dev Check if the time is expired past the start time lock.
     * @return True if time is expired past start time lock, false otherwise.
     */
    function timeLockExpired() internal view returns (bool) {
        return startTime > 0 && block.timestamp > (startTime + startLock);
    }

    /**
     * @dev Calculate the time at which the lock will cancel.
     * This is an assembly-optimized version of comparing startTime + startLock with lastTime + lastLock.
     * @return The time at which the lock will cancel.
     */
    function _cancelTime(uint256 _startLock, uint256 _lastLock) private view returns (uint256) {
        uint256 result;
        assembly {
            let s := add(sload(startTime.slot), _startLock)
            let l := add(sload(lastTime.slot), _lastLock)
            result := or(mul(lt(s, l), s), mul(iszero(lt(s, l)), l))
        }
        return result;
    }
}
