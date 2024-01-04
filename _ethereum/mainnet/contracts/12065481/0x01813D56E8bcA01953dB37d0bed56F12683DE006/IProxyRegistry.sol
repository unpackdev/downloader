// SPDX-License-Identifier: WTFPL
pragma solidity ^0.6.0;

contract OwnableDelegateProxy {}

contract IProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
