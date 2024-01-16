//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./console.sol";

abstract contract ProxyableUpgradeable is Initializable, OwnableUpgradeable {
    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "Only proxy");
        _;
    }

    function __ProxyableUpgradeable_init() internal onlyInitializing {
        __ProxyableUpgradeable_init_unchained();
    }

    function __ProxyableUpgradeable_init_unchained() internal onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
    }

    function setProxyState(address proxyAddress, bool value)
        public
        virtual
        onlyOwner
    {
        proxyToApproved[proxyAddress] = value;
    }
}
