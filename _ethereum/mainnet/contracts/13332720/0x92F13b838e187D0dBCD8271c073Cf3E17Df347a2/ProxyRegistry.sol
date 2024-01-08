// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableDelegateProxy.sol";

abstract contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
