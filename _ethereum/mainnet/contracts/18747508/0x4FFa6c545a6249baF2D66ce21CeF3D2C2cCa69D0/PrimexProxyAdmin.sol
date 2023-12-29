// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./ProxyAdmin.sol";
import "./UpgradeableBeacon.sol";
import "./IAccessControl.sol";
import "./IERC165.sol";

import "./Errors.sol";
import "./Constants.sol";
import "./IPrimexProxyAdmin.sol";

/**
 * @dev This is openzeppelin proxy admin with AccessControl access.
 * Also, there remains the functionality of the Ownable contract
 * for compatibility with the hardhat-deploy plugin,
 * but it does not give privileged access
 */
contract PrimexProxyAdmin is ProxyAdmin, IPrimexProxyAdmin {
    address public immutable registry;

    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(address _registry) {
        _transferOwnership(address(this));
        _require(
            IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        ITransparentUpgradeableProxy proxy,
        address newAdmin
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Changes the admin of the `beacon` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeBeaconProxyAdmin(
        UpgradeableBeacon beacon,
        address newAdmin
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        beacon.transferOwnership(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(
        ITransparentUpgradeableProxy proxy,
        address implementation
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable override onlyRole(BIG_TIMELOCK_ADMIN) {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }

    /**
     * @dev Upgrades the beacon to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     * - implementation must be a contract.
     */

    function upgradeBeacon(
        UpgradeableBeacon beacon,
        address implementation
    ) public override onlyRole(BIG_TIMELOCK_ADMIN) {
        beacon.upgradeTo(implementation);
    }
}
