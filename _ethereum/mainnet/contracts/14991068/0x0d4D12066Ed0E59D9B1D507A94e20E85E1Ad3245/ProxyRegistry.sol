// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OwnableDelegateProxy {} // solhint-disable no-empty-blocks

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
