pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ModuleLib.sol";

library CurveAdapterLib {
  struct Isolate {
    address curveAddress;
  }
  function getCastStorageType() internal pure returns (function (uint256) internal pure returns (Isolate storage) swap) {
    function (uint256) internal returns (uint256) cast = ModuleLib.cast;
    assembly {
      swap := cast
    }
  }
  function toIsolatePointer(uint256 key) internal pure returns (Isolate storage) {
    return getCastStorageType()(key);
  }
  function computeIsolatePointer(address instance) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked("isolate.curve-adapter", instance)));
  }
  function getIsolatePointer(address instance) internal pure returns (Isolate storage) {
    return toIsolatePointer(computeIsolatePointer(instance));
  }
  struct ExchangeInputs {
    int128 i;
    int128 j;
    uint256 dx;
    uint256 min_dy;
  }
  function decodeExchangeInputs(bytes memory args) internal pure returns (ExchangeInputs memory) {
    (int128 i, int128 j, uint256 dx, uint256 min_dy) = abi.decode(args, (int128, int128, uint256, uint256));
    return ExchangeInputs({
      i: i,
      j: j,
      dx: dx,
      min_dy: min_dy
    });
  }
}
