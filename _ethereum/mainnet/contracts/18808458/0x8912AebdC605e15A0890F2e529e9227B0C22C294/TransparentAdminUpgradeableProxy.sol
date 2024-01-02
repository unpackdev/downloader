// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.20;

import "./ERC1967Utils.sol";
import "./ERC1967Proxy.sol";
import "./IERC1967.sol";

interface ITransparentAdminUpgradeableProxy is IERC1967 {
    function upgradeToAndCall(address, bytes calldata) external payable;
}

contract TransparentAdminUpgradeableProxy is ERC1967Proxy {
    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev Initializes an upgradeable proxy with an `initialOwner`,
     * backed by the implementation at `_logic`, and optionally initialized with `_data` as explained in
     * {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _admin = admin;
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }

    /**
     * @dev Returns the admin of this proxy.
     */
    function _proxyAdmin() internal virtual returns (address) {
        return _admin;
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    function _fallback() internal virtual override {
        if (msg.sender == _proxyAdmin()) {
            if (msg.sig != ITransparentAdminUpgradeableProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeToAndCall();
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Upgrade the implementation of the proxy. See {ERC1967Utils-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    function _dispatchUpgradeToAndCall() private {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}
