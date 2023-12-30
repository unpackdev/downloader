// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./MemcpyLib.sol";

library ConcatLib {
  function concat(bytes memory left, bytes memory right) internal pure returns (bytes memory joined) {
    joined = new bytes(left.length + right.length);
    bytes32 joinedPtr;
    bytes32 leftPtr;
    bytes32 middlePtr;
    bytes32 rightPtr;
    uint256 leftLen = left.length;
    assembly {
      leftPtr := add(0x20, left)
      joinedPtr := add(0x20, joined)
      middlePtr := add(joinedPtr, leftLen)
      rightPtr := add(0x20, right)
    }
    MemcpyLib.memcpy(joinedPtr, leftPtr, leftLen);
    MemcpyLib.memcpy(middlePtr, rightPtr, right.length);
    return joined;
  }
}
