//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";

library CalldataLoader {
  using SafeMath for uint;

  function loadUint8(uint self) pure internal returns (uint x) {
    assembly {
      x := shr(248, calldataload(self))
    }
  }
  function loadUint16(uint self) pure internal returns (uint x) {
    assembly {
      x := shr(240, calldataload(self))
    }
  }
  function loadAddress(uint self) pure internal returns (address x) {
    assembly {
      x := shr(96, calldataload(self)) // 12 * 8 = 96
    }
  }
  function loadTokenFromArray(uint self) pure internal returns (address x) {
    assembly {
      x := shr(96, calldataload(add(73, mul(20, self)))) // 73 = 68 + 5
    }
  }
  function loadVariableUint(uint self, uint len) pure internal returns (uint x) {
    uint extra = uint(32).sub(len) << 3;
    assembly {
      x := shr(extra, calldataload(self))
    }
  }
}
