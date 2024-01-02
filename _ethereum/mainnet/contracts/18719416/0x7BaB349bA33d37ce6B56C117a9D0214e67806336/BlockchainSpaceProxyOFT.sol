// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ProxyOFT.sol";

contract BlockchainSpaceProxyOFT is ProxyOFT {
  constructor(address _layerZeroEndpoint, address _token) ProxyOFT(_layerZeroEndpoint, _token) {}
}
