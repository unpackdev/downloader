//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Provides modifier for debouncing call to methods,
/// i.e. method cannot be called more earlier than debouncePeriod
/// since the last call
abstract contract Debouncable {
    /// Debounce period in secs
    uint256 public immutable debouncePeriod;
    /// Last time method successfully called (block timestamp)
    uint256 public lastCalled;

    /// @param _debouncePeriod Debounce period in secs
    constructor(uint256 _debouncePeriod) internal {
        debouncePeriod = _debouncePeriod;
    }

    /// Throws if the method was called earlier than debouncePeriod last time.
    /// @dev !!! This modifier must be accompanied by the _commitDebounceCall(),
    /// typically at the last line of the method.
    modifier debounce() {
        uint256 timeElapsed = block.timestamp - lastCalled;
        require(
            timeElapsed >= debouncePeriod,
            "Debouncable: already called in this time slot"
        );
        _;
    }

    /// Save the time of the last call
    function _commitDebounce() internal {
        lastCalled = block.timestamp;
    }
}
