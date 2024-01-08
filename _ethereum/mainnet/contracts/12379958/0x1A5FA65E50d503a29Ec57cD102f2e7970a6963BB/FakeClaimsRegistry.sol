// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ClaimsRegistry.sol";

/// @title Calculates rewards based on an initial downward curve period, and a second linear period
/// @author Miguel Palhas <miguel@subvisual.co>
contract FakeClaimsRegistry is IClaimsRegistryVerifier {
  bool result;

  constructor() {
    result = true;
  }

  function setResult(bool _r) public {
    result = _r;
  }

  function verifyClaim(address, address, bytes calldata) external override view returns (bool) {
    return result;
  }
}
