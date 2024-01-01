// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ProxyAdmin.sol";

contract DefaultProxyAdmin is ProxyAdmin {
    constructor(address _owner) ProxyAdmin(_owner) {}
}
