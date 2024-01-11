// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ProxyRegistry.sol";
import "./AuthenticatedProxy.sol";

/**
 * @title WyvernRegistry
 * @author Wyvern Protocol Developers
 */
contract LegitArtRegistry is ProxyRegistry {
    string public constant name = "LegitArt Protocol Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    constructor() {
        AuthenticatedProxy impl = new AuthenticatedProxy();
        impl.initialize(address(this), this);
        impl.setRevoke(true);
        delegateProxyImplementation = address(impl);
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication(address authAddress) public onlyOwner {
        require(!initialAddressSet, "LegitArt Protocol Proxy Registry initial address already set");
        initialAddressSet = true;
        contracts[authAddress] = true;
    }
}
