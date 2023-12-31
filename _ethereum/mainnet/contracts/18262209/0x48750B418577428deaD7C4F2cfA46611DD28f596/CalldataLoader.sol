//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "./SafeMath.sol";

library CalldataLoader {
//  using SafeMath for uint;

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
  function loadUint24(uint self) pure internal returns (uint x) {
    assembly {
      x := shr(232, calldataload(self))
    }
  }
  function loadUint256(uint self) pure internal returns (uint x) {
    assembly {
      x := calldataload(self)
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
  function loadTokenFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (address x) {
    assembly {
      x := shr(96, calldataload(add(start_ind, mul(20, arr_idx))))
    }
  }
//  function loadTotalsFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
//    assembly {
//      x := calldataload(add(start_ind, mul(32, arr_idx)))
//    }
//  }
//  function loadExpectedFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
//    assembly {
//      x := calldataload(add(start_ind, mul(32, arr_idx)))
//    }
//  }
//  function loadBalancesFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
//    assembly {
//      x := calldataload(add(start_ind, mul(32, arr_idx)))
//    }
//  }
  function loadVariableUint(uint self, uint len) pure internal returns (uint x) {
    uint extra = (uint(32) - len) << 3;
    assembly {
      x := shr(extra, calldataload(self))
    }
  }
}

//library BytesLoader {
////  using SafeMath for uint;
//
//  function mloadUint8(uint self) pure internal returns (uint x) {
//    assembly {
//      x := shr(248, mload(self))
//    }
//  }
//  function mloadUint16(uint self) pure internal returns (uint x) {
//    assembly {
//      x := shr(240, mload(self))
//    }
//  }
//  function mloadUint24(uint self) pure internal returns (uint x) {
//    assembly {
//      x := shr(232, mload(self))
//    }
//  }
//  function mloadUint256(uint self) pure internal returns (uint x) {
//    assembly {
//      x := mload(self)
//    }
//  }
//  function mloadAddress(uint self) pure internal returns (address x) {
//    assembly {
//      x := shr(96, mload(self)) // 12 * 8 = 96
//    }
//  }
////  function mloadTokenFromArray(uint self) pure internal returns (address x) {
////    assembly {
////      x := shr(96, mload(add(73, mul(20, self)))) // 73 = 68 + 5
////    }
////  }
//  function mloadTokenFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (address x) {
//    assembly {
//      x := shr(96, mload(add(start_ind, mul(20, arr_idx))))
//    }
//  }
////  function mloadTotalsFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
////    assembly {
////      x := mload(add(start_ind, mul(32, arr_idx)))
////    }
////  }
////  function mtopUpTotalsAtArrayV4(uint arr_idx, uint start_ind, uint extra) pure internal returns (uint x) {
////    uint addr = start_ind + arr_idx * 32;
////    uint v;
////    assembly {
////      v := mload(addr)
////    }
////    v += extra;
////    assembly {
////      mstore(addr, v)
////    }
////  }
////  function mloadExpectedFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
////    assembly {
////      x := mload(add(start_ind, mul(32, arr_idx)))
////    }
////  }
////  function mtopUpExpectedAtArrayV4(uint arr_idx, uint start_ind, uint extra) pure internal returns (uint x) {
////    uint addr = start_ind + arr_idx * 32;
////    uint v;
////    assembly {
////      v := mload(addr)
////    }
////    v += extra;
////    assembly {
////      mstore(addr, v)
////    }
////  }
////  function mloadBalancesFromArrayV4(uint arr_idx, uint start_ind) pure internal returns (uint x) {
////    assembly {
////      x := mload(add(start_ind, mul(32, arr_idx)))
////    }
////  }
////  function mtopUpBalancesAtArrayV4(uint arr_idx, uint start_ind, uint extra) pure internal returns (uint x) {
////    uint addr = start_ind + arr_idx * 32;
////    uint v;
////    assembly {
////      v := mload(addr)
////    }
////    v += extra;
////    assembly {
////      mstore(addr, v)
////    }
////  }
////  function mwithdrawBalancesAtArrayV4(uint arr_idx, uint start_ind, uint extra) pure internal returns (uint x) {
////    uint addr = start_ind + arr_idx * 32;
////    uint v;
////    assembly {
////      v := mload(addr)
////    }
////    v -= extra;
////    assembly {
////      mstore(addr, v)
////    }
////  }
////  function mtopUpTotalFrom(uint ind, uint extra) pure internal returns (uint x) {
////    uint v;
////    assembly {
////      v := mload(ind)
////    }
////    v += extra;
////    assembly {
////      mstore(ind, v)
////    }
////  }
//  function mloadVariableUint(uint self, uint len) pure internal returns (uint x) {
//    uint extra = (uint(32) - len) << 3;
//    assembly {
//      x := shr(extra, mload(self))
//    }
//  }
//}
