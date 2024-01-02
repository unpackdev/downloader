// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./ProxyOFTV2.sol";

contract RebaseProxyOFT is ProxyOFTV2 {
    constructor(address _token, address _lzEndpoint) ProxyOFTV2(_token, 8, _lzEndpoint) {}
}