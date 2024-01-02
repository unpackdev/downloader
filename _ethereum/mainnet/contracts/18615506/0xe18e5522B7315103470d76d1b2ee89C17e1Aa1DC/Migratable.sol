// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import "./IMigratable.sol";

/**
 * @title Migratable
 * @notice Mixin responsible for managing Vault's migration capability.
 * This contract allows the owner to set up a migration to a new Vault.
 * It is intended to be used as a mixin for Vault contracts.
 * @author Pods Finance
 */
abstract contract Migratable is IMigratable {
    // Address of the Contract to migrate to
    address private _migrateDest;
    // Address of the Contract to migrate from
    address private _migrateSource;

    /**
     * @notice Enables migration to a specified destination contract.
     * @dev Sets the _migrateDest to the provided address. Can be called only by the owner.
     * Emits a Migratable__MigrationChanged event with the destination address.
     * @param destination The address of the contract to migrate to.
     */
    function enableMigration(address destination) external virtual {
        _enableMigration(destination);
    }

    /**
     * @notice Receives migration from a specified source contract.
     * @dev Sets the _migrateSource to the provided address. This function should be paired
     * with logic to handle incoming migration data or states.
     * @param source The address of the contract migrating to this contract.
     */
    function receiveMigration(address source) external virtual {
        _receiveMigration(source);
    }

    /**
     * @notice Cancels the current migration process.
     * @dev Resets both the _migrateDest and _migrateSource addresses to the zero address.
     * Emits a Migratable__MigrationChanged event with a zero address.
     */
    function cancelMigration() external virtual {
        _cancelMigration();
    }

    // Internal functions for migration management

    function _enableMigration(address destination) internal {
        _migrateDest = destination;
        emit Migratable__MigrationChanged(_migrateDest);
    }

    function _receiveMigration(address source) internal {
        _migrateSource = source;
        emit Migratable__MigrationChanged(_migrateSource);
    }

    function _cancelMigration() internal {
        _migrateDest = address(0);
        _migrateSource = address(0);
        emit Migratable__MigrationChanged(address(0));
    }

    /**
     * @notice Gets the destination address for migration.
     * @return The address of the contract to migrate to.
     */
    function getMigrationDestination() public view returns (address) {
        return _migrateDest;
    }

    /**
     * @notice Gets the source address for migration.
     * @return The address of the contract migrating to this contract.
     */
    function getMigrationSource() public view returns (address) {
        return _migrateSource;
    }
}
