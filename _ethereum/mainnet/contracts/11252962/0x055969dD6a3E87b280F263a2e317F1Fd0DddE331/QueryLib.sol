// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library QueryLib {
  function returnBytes(bytes memory buffer) internal pure {
    assembly {
      return(add(0x20, buffer), mload(buffer))
    }
  }
}

