// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./BeaconProxy.sol";

/**
 * @dev This contract implements a beacon proxy that is upgradeable by an immutable admin.
 *
 */
contract ImmutableAdminUpgradeableBeaconProxy is BeaconProxy {
    address private immutable _admin;

    /**
     * @dev Initializes an upgradeable proxy managed by `admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _beacon,
        address admin_,
        bytes memory _data
    ) payable BeaconProxy(_beacon, _data) {
        // cheaper deployments
        // slither-disable-next-line missing-zero-check
        _admin = admin_;
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    // slither-disable-next-line incorrect-modifier
    modifier ifAdmin() {
        if (msg.sender == _admin) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin;
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation()
        external
        ifAdmin
        returns (address implementation_)
    {
        implementation_ = super._implementation();
    }

    /**
     * @dev Upgrade the beacon of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address beacon) external ifAdmin {
        _upgradeBeaconToAndCall(beacon, bytes(""), false);
    }

    /**
     * @dev Upgrade the beacon of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address beacon, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeBeaconToAndCall(beacon, data, true);
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(
            msg.sender != _admin,
            "ImmutableAdminUpgradeableBeaconProxy: admin cannot fallback to proxy target"
        );
        super._beforeFallback();
    }
}
