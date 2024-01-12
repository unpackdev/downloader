// SPDX-License-Identifier: MIT

import "./ZeroUnderwriterLock.sol";

library ZeroUnderwriterLockBytecodeLib {
  function get() external pure returns (bytes memory result) {
    result = type(ZeroUnderwriterLock).creationCode;
  }
}
