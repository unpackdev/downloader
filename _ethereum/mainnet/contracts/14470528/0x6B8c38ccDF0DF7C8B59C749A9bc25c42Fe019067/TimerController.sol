// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./TimerLib.sol";

/**
 * @dev Timer lib provides functionality to use time easily
 * with guarding and general functionality for contracts,
 * call _startTimer(time) before calling any other method
 */

struct TimerData {
    /// the time the contract started (seconds)
    uint256 startTime;
    /// the time the contract is running from startTime (seconds)
    uint256 runningTime;
}

contract TimerController {
    using TimerLib for TimerLib.Timer;
    TimerLib.Timer private _timer;

    /// @dev makes sure the timer is running
    modifier onlyRunning() {
        require(_isTimerRunning(), "timer over");
        _;
    }

    /// @dev returns the timer data
    function _getTimerData() internal view returns (TimerData memory) {
        return TimerData(_timer.startTime, _timer.runningTime);
    }

    /// @dev checks if the timer is still running
    function _isTimerRunning() internal view returns (bool) {
        return _timer._isRunning();
    }

    /// @dev should be called in the constructor
    function _startTimer(uint256 endsInHours) internal {
        _timer._start(endsInHours * 1 hours);
    }

    /// @dev set a new end time in hours (from the given time)
    function _setTimerEndsInHours(uint256 endsInHours) internal {
        _timer._updateRunningTime(endsInHours * 1 hours);
    }
}
