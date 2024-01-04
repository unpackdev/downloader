// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
