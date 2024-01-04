// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library WSBTimeLockLib {
  enum TimeLockState {
    UNINITIALIZED,
    INITIALIZED,
    DONE
  }
  uint256 constant DONE = uint256(~0);
  uint256 constant UNINITIALIZED = uint256(0);
  function getState(TimeLock storage lock) internal view returns (TimeLockState state) {
    if (lock.release == UNINITIALIZED) return TimeLockState.UNINITIALIZED;
    else if (lock.release == DONE) return TimeLockState.DONE;
    else return TimeLockState.INITIALIZED;
  }
  function markDone(TimeLock storage lock) internal {
    lock.release = DONE;
  }
  struct TimeLock {
    uint256 amount;
    uint256 release;
  }
}
