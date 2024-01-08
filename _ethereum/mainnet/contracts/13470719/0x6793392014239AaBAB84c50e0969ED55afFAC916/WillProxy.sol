/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "./Proxy.sol";
import "./StorageSlot.sol";
import "./Registry.sol";

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract WillProxy is Proxy {
    /**
     * @dev Storage slot with the address of the current Registry.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _REGISTRY_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /** @notice initializes the proxy with a registry
     * @param registry registry location to get implementations
     */
    constructor(address registry) payable {
        StorageSlot.getAddressSlot(_REGISTRY_SLOT).value = registry;
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = msg.sender;
    }

    /**
     * @dev returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address impl)
    {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        // Call the registry to get the implementation of the caller
        try registry.getImplementation(msg.sender) returns (address _impl) {
            return _impl;
        } catch {
            return address(0);
        }
    }

    /** @notice Upgrades user to the latest version
     */
    function upgrade() public {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.upgrade(msg.sender) {
            return;
        } catch {
            return;
        }
    }

    /** @notice Upgrades user to the specified version
     * @param version implementation version to set
     */
    function upgradeToVersion(uint256 version) public {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.upgradeToVersion(msg.sender, version) {
            return;
        } catch {
            return;
        }
    }

    /** @notice Gets implementation address for user
     * @return address of the implementation version for the user
     */
    function getImplementation() public view returns (address) {
        address registryAddress = StorageSlot
            .getAddressSlot(_REGISTRY_SLOT)
            .value;
        Registry registry = Registry(registryAddress);

        try registry.getImplementation(msg.sender) returns (address _impl) {
            return _impl;
        } catch {
            return address(0);
        }
    }
}
