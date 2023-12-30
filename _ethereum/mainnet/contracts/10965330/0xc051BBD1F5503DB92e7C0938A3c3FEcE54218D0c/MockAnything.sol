// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract MockAnything {
  fallback() external payable {
    assembly {
      return(mload(0x40), 0x60)
    }
  }
}
