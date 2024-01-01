// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ProxyOFT.sol";


contract AminoBridge is ProxyOFT {
    constructor(address _lzEndpoint, address _token) ProxyOFT(_lzEndpoint, _token) {}

}
