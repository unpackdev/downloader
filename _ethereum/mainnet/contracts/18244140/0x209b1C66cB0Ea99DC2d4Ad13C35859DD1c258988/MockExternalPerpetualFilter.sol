// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IExternalPerpetualFilter.sol";

contract MockExternalPerpetualFilter is IExternalPerpetualFilter {
  bool internal _isPerpetual = false;
  function setVerifyPerpetualResult(bool result) external {
    _isPerpetual = result;
  }
  function verifyPerpetual(address) external view returns(bool) {
    return _isPerpetual;
  }
}
