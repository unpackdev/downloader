// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Proxy.sol";

/**
 * @title VaultProxy
 * @notice Basic proxy that delegates all calls to a fixed implementing contract.
 * The implementing contract cannot be upgraded.
 */
contract VaultProxy is Proxy{

    address public immutable implementation;

    /**
     * @param _impl deployed instance of base vault.
     */
    constructor(address _impl) {
        implementation = _impl;
    }

    /**
     * @inheritdoc Proxy
     */
    function _implementation() internal view override returns(address) {
        return implementation;
    }
}