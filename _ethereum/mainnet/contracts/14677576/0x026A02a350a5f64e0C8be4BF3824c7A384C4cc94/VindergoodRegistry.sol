// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./ReentrancyGuardUpgradeable.sol";
import "./ProxyRegistry.sol";
import "./AuthenticatedProxy.sol";

contract VindergoodRegistry is ProxyRegistry, ReentrancyGuardUpgradeable {
    string public constant name = "Wyvern Protocol Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    function initialize() external initializer {
        AuthenticatedProxy impl = new AuthenticatedProxy();
        impl.initialize(address(this), this);
        impl.setRevoke(true);
        delegateProxyImplementation = address(impl);
        __Ownable_init();
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication(address authAddress) public onlyOwner {
        require(
            !initialAddressSet,
            "Wyvern Protocol Proxy Registry initial address already set"
        );
        initialAddressSet = true;
        contracts[authAddress] = true;
    }
}
