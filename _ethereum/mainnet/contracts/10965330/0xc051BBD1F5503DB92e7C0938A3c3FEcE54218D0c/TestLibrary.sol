// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FauxblocksLib.sol";

contract TestLibrary {
  struct Result {
    address controller;
    uint256 packed;
    uint256 argument;
  }
  function test(uint256 a) public pure returns (Result memory result) {
    bytes memory context = FauxblocksLib.getContext();
    (uint256 packed) = abi.decode(context, (uint256));
    result = Result({
      controller: FauxblocksLib.getController(),
      packed: packed,
      argument: a
    });
  }
}
