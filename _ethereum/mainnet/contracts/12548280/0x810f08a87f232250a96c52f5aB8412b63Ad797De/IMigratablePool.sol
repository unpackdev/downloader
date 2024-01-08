// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Deri Protocol migratable pool interface
 */
interface IMigratablePool {

    /**
     * @dev Emitted when migration is prepared
     * `source` pool will be migrated to `target` pool after `migrationTimestamp`
     */
    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Emmited when migration is executed
     * `source` pool is migrated to `target` pool
     */
    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    /**
     * @dev Set controller to `newController`
     *
     * can only be called by current controller or the controller has not been set
     */
    function setController(address newController) external;

    /**
     * @dev Returns address of current controller
     */
    function controller() external view returns (address);

    /**
     * @dev Returns the migrationTimestamp of this pool, zero means not set
     */
    function migrationTimestamp() external view returns (uint256);

    /**
     * @dev Returns the destination pool this pool will migrate to after grace period
     * zero address means not set
     */
    function migrationDestination() external view returns (address);

    /**
     * @dev Prepare a migration from this pool to `newPool` with `graceDays` as grace period
     * `graceDays` must be at least 3 days from now, allow users to verify the `newPool` code
     *
     * can only be called by controller
     */
    function prepareMigration(address newPool, uint256 graceDays) external;

    /**
     * @dev Approve migration to `newPool` when grace period ends
     * after approvement, current pool will stop functioning
     *
     * can only be called by controller
     */
    function approveMigration() external;

    /**
     * @dev Called from the `newPool` to migrate from `source` pool
     * the grace period of `source` pool must ends
     * current pool must be the destination pool set before grace period in the `source` pool
     *
     * can only be called by controller
     */
    function executeMigration(address source) external;

}
