// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "TransparentUpgradeableProxy.sol";
import "EnumerableSet.sol";

import "Errors.sol";

/**
 * @notice This is take from OpenZeppelin Contracts (proxy/transparent/ProxyAdmin.sol) and adapted to be able to have multiple owners
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract MultiownerProxyAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    EnumerableSet.AddressSet internal _owners;

    modifier onlyOwner() {
        if (!_owners.contains(msg.sender))
            revert Errors.NotAuthorized(msg.sender, _owners.at(0));
        _;
    }

    constructor() {
        _addOwner(msg.sender);
    }

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(
        TransparentUpgradeableProxy proxy
    ) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(
        TransparentUpgradeableProxy proxy
    ) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(
        TransparentUpgradeableProxy proxy,
        address implementation
    ) public virtual onlyOwner {
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
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }

    function addOwner(address newOwner) public virtual onlyOwner {
        _addOwner(newOwner);
    }

    function removeOwner(address owner) public virtual onlyOwner {
        require(_owners.length() > 1, "cannot remove last owner");
        _owners.remove(owner);
        emit OwnerRemoved(owner);
    }

    function owners() public view returns (address[] memory) {
        return _owners.values();
    }

    function _addOwner(address newOwner) internal {
        _owners.add(newOwner);
        emit OwnerAdded(newOwner);
    }
}
