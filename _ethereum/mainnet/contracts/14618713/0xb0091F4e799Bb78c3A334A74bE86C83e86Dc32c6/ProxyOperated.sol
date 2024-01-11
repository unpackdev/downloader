// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev An extension that grants approvals to proxy operators.
 * Inspired by NuclearNerds' implementation.
 */
contract ProxyOperated is Ownable {
    address public proxyRegistryAddress;
    mapping(address => bool) public projectProxy;

    constructor(address proxy) {
        proxyRegistryAddress = proxy;
    }

    function toggleProxyState(address proxy) external onlyOwner {
        projectProxy[proxy] = !projectProxy[proxy];
    }

    function setProxyRegistryAddress(address proxy) external onlyOwner {
        proxyRegistryAddress = proxy;
    }

    function _isProxyApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        bool isApproved;

        if (proxyRegistryAddress != address(0)) {
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
                proxyRegistryAddress
            );
            isApproved = address(proxyRegistry.proxies(owner)) == operator;
        }

        return isApproved || projectProxy[operator];
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
