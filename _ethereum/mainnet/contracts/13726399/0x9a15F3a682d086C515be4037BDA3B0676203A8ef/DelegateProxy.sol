pragma solidity ^0.5.2;

import "./ERCProxy.sol";
import "./DelegateProxyForwarder.sol";

contract DelegateProxy is ERCProxy, DelegateProxyForwarder {
    function proxyType() external pure returns (uint256 proxyTypeId) {
        // Upgradeable proxy
        proxyTypeId = 2;
    }

    function implementation() external view returns (address);
}
