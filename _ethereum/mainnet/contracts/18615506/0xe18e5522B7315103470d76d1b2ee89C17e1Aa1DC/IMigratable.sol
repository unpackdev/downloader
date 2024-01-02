// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/**
 * @title IMigratable
 * @notice Interface for managing Vault's migration capability.
 * This interface represents the functionality to set up a migration to a new Vault.
 * It is intended to be used as a mixin for Vault contracts.
 * @author Pods Finance
 */
interface IMigratable {
    event Migratable__MigrationChanged(address indexed migrationAddress);

    error Migratable__MigrationNotAllowed();

    /**
     * @notice Enables migration to a specified destination contract.
     * @dev Sets the _migrateDest to the provided address. Can be called only by the owner.
     * Emits a Migratable__MigrationChanged event with the destination address.
     * @param destination The address of the contract to migrate to.
     */
    function enableMigration(address destination) external;

    /**
     * @notice Receives migration from a specified source contract.
     * @dev Sets the _migrateSource to the provided address. This function should be paired
     * with logic to handle incoming migration data or states.
     * @param source The address of the contract migrating to this contract.
     */
    function receiveMigration(address source) external;

    /**
     * @notice Cancels the current migration process.
     * @dev Resets both the _migrateDest and _migrateSource addresses to the zero address.
     * Emits a Migratable__MigrationChanged event with a zero address.
     */
    function cancelMigration() external;

    /**
     * @notice Gets the destination address for migration.
     * @return The address of the contract to migrate to.
     */
    function getMigrationDestination() external view returns (address);

    /**
     * @notice Gets the source address for migration.
     * @return The address of the contract migrating to this contract.
     */
    function getMigrationSource() external view returns (address);
}
