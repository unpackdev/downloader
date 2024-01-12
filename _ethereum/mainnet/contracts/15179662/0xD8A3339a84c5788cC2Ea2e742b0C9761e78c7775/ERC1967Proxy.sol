// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.15;

import "./Proxy.sol";
import "./ERC1967UpgradeUpgradeable.sol";

contract ERC1967Proxy is Proxy, ERC1967UpgradeUpgradeable {
    constructor(address _logic, bytes memory _data) {
        _upgradeToAndCall(_logic, _data, false);
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        return ERC1967UpgradeUpgradeable._getImplementation();
    }
}
