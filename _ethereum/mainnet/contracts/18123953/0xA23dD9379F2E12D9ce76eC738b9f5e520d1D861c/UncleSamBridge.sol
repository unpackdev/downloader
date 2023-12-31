// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ProxyOFT.sol";

contract UncleSamBridge is ProxyOFT {
    constructor(address _lzEndpoint, address _token) ProxyOFT(_lzEndpoint, _token) {
    }
}