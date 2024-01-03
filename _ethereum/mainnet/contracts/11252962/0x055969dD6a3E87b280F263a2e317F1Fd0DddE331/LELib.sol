// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library LELib {
  function toLE16(uint16 sz) internal pure returns (bytes memory buffer) {
    bytes2 casted = bytes2(sz);
    buffer = new bytes(2);
    assembly {
      mstore(add(0x20, buffer), casted)
    }
    byte tmp = buffer[0];
    buffer[0] = buffer[1];
    buffer[1] = tmp;
  }
  function toLE32(uint32 sz) internal pure returns (bytes memory buffer) {
    bytes4 casted = bytes4(sz);
    buffer = new bytes(4);
    assembly {
      mstore(add(0x20, buffer), casted)
    }
    byte tmp = buffer[0];
    buffer[0] = buffer[3];
    buffer[3] = tmp;
    tmp = buffer[1];
    buffer[1] = buffer[2];
    buffer[2] = tmp;
  }
}
