// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Timer lib provides functionality to use time easily,
 * call _start(time) before calling any other method
 */

library TimerLib {
    struct Timer {
        /// @dev the time the contract started
        uint256 startTime;
        /// @dev the time the contract is running from startTime
        uint256 runningTime;
        /// @dev is the timer running
        bool isRunning;
    }

    /// @dev is the timer running - marked as running and has time remaining
    function _isRunning(Timer storage self) internal view returns (bool) {
        return
            self.isRunning &&
            // solhint-disable-next-line not-rely-on-time
            (self.startTime + self.runningTime > block.timestamp);
    }

    /// @dev starts the timer, call again to restart
    function _start(Timer storage self, uint256 runningTime) internal {
        self.isRunning = true;
        // solhint-disable-next-line not-rely-on-time
        self.startTime = block.timestamp;
        self.runningTime = runningTime;
    }

    /// @dev updates the running time
    function _updateRunningTime(Timer storage self, uint256 runningTime)
        internal
    {
        self.runningTime = runningTime;
    }
}
