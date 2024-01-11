// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AssemblyMath {
  function arraySumAssembly(uint256[] memory d)
    internal
    pure
    returns (uint256 sum)
  {
    assembly {
      let len := mload(d)
      let data := add(d, 0x20)
      for {
        let end := add(data, mul(len, 0x20))
      } lt(data, end) {
        data := add(data, 0x20)
      } {
        sum := add(sum, mload(data))
      }
    }
  }
}
