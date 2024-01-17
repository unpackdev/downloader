// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./Proxy.sol";
import "./IUpgradeableProxy.sol";
import "./UpgradeableProxyStorage.sol";

/**
 * @title Proxy with upgradeable implementation
 */
abstract contract UpgradeableProxy is IUpgradeableProxy, Proxy {
    using UpgradeableProxyStorage for UpgradeableProxyStorage.Layout;

    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        // inline storage layout retrieval uses less gas
        UpgradeableProxyStorage.Layout storage l;
        bytes32 slot = UpgradeableProxyStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        return l.implementation;
    }

    /**
     * @notice set logic implementation address
     * @param implementation implementation address
     */
    function _setImplementation(address implementation) internal {
        UpgradeableProxyStorage.layout().setImplementation(implementation);
    }
}
