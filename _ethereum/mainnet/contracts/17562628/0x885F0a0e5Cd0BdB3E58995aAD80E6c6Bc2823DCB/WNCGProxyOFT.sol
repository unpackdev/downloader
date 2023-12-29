// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyOFTWithFee.sol";

contract WNCGProxyOFT is ProxyOFTWithFee {
  constructor(address _token, uint8 _sharedDecimals, address _lzEndpoint)
    ProxyOFTWithFee(_token, _sharedDecimals, _lzEndpoint) {
  }
}
