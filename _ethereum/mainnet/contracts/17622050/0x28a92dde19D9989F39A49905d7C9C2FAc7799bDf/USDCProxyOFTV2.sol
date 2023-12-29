// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyOFTV2.sol";

contract USDCProxyOFTV2 is ProxyOFTV2 {
    constructor(address _token, address _layerZeroEndpoint) ProxyOFTV2(_token, 6, _layerZeroEndpoint){}
}