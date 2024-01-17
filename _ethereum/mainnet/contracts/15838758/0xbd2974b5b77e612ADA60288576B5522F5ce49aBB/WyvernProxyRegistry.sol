/*

  << Project Wyvern Proxy Registry >>

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./ProxyRegistry.sol";
import "./AuthenticatedProxy.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title WyvernProxyRegistry
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract WyvernProxyRegistry is ProxyRegistry, UUPSUpgradeable {

    string public constant name = "Project Wyvern Proxy Registry";

    /* Whether the initial auth address has been set. */
     bool public initialAddressSet;

    function initialize(address _contractOwner) external initializer {
        require(_contractOwner != address(0), "Invalid owner");
        __ProxyRegistry_init();
        initialAddressSet = false;
        AuthenticatedProxy ap = new AuthenticatedProxy();
        delegateProxyImplementation = address(ap);
        _transferOwnership(_contractOwner);
    }

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication (address authAddress)
    onlyOwner
    external
    {
        require(authAddress != address(0), "AuthAddress cannot be zero address");
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[authAddress] = true;
    }

}
