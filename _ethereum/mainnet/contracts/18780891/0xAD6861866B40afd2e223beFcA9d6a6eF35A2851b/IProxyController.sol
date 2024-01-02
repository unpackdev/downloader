// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IProxyController {
    error InvalidProxyContract();

    event ProxyUpdated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed newImplementationAddress,
        address oldImplementationAddress
    );
}
