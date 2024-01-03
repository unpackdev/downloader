pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library ExtLib {
  function getExtCodeHash(address target) internal view returns (bytes32 result) {
    assembly {
      result := extcodehash(target)
    }
  }
  function isContract(address target) internal view returns (bool result) {
    assembly {
      result := iszero(iszero(extcodesize(target)))
    }
  }
}
