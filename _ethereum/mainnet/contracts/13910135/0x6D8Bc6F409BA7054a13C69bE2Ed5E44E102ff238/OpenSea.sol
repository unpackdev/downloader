//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
