// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlDefaultAdminRules declared to support ERC165 detection.
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/3e6c86392c97fbc30d3d20a378a6f58beba08eba/contracts/access/extensions/IAccessControlDefaultAdminRules.sol
 * Changes:
 * 1. Remove AccessControlEnforcedDefaultAdminDelay error
 * 2. Remove acceptSchedule from event DefaultAdminTransferScheduled
 * 3. Remove DefaultAdminDelayChangeScheduled/DefaultAdminDelayChangeCanceled event
 * 5. Remove acceptSchedule from pendingDefaultAdmin function
 * 6. Remove defaultAdminDelay/pendingDefaultAdminDelay/changeDefaultAdminDelay/rollbackDefaultAdminDelay/defaultAdminDelayIncreaseWait function
 */

interface IAccessControlDefaultAdminRules is IAccessControl {
    /**
     * @dev The new default admin is not a valid default admin.
     */
    error AccessControlInvalidDefaultAdmin(address defaultAdmin);

    /**
     * @dev At least one of the following rules was violated:
     *
     * - The `DEFAULT_ADMIN_ROLE` must only be managed by itself.
     * - The `DEFAULT_ADMIN_ROLE` must only be held by one account at the time.
     * - Any `DEFAULT_ADMIN_ROLE` transfer must be in two delayed steps.
     */
    error AccessControlEnforcedDefaultAdminRules();

    /**
     * @dev Emitted when a {defaultAdmin} transfer is started, setting `newAdmin` as the next
     * address to become the {defaultAdmin} by calling {acceptDefaultAdminTransfer}
     */
    event DefaultAdminTransferScheduled(address indexed newAdmin);

    /**
     * @dev Emitted when a {pendingDefaultAdmin} is reset if it was never accepted
     */
    event DefaultAdminTransferCanceled();

    /**
     * @dev Returns the address of the current `DEFAULT_ADMIN_ROLE` holder.
     */
    function defaultAdmin() external view returns (address);

    /**
     * @dev Returns `newAdmin` address
     *
     * `newAdmin` will be able to accept the {defaultAdmin} role
     * by calling {acceptDefaultAdminTransfer}, completing the role transfer.
     *
     * NOTE: A zero address `newAdmin` means that {defaultAdmin} is being renounced.
     */
    function pendingDefaultAdmin() external view returns (address newAdmin);

    /**
     * @dev Starts a {defaultAdmin} transfer by setting a {pendingDefaultAdmin}
     *
     * Requirements:
     *
     * - Only can be called by the current {defaultAdmin}.
     *
     * Emits a DefaultAdminRoleChangeStarted event.
     */
    function beginDefaultAdminTransfer(address newAdmin) external;

    /**
     * @dev Cancels a {defaultAdmin} transfer previously started with {beginDefaultAdminTransfer}.
     *
     * A {pendingDefaultAdmin} not yet accepted can also be cancelled with this function.
     *
     * Requirements:
     *
     * - Only can be called by the current {defaultAdmin}.
     *
     * May emit a DefaultAdminTransferCanceled event.
     */
    function cancelDefaultAdminTransfer() external;

    /**
     * @dev Completes a {defaultAdmin} transfer previously started with {beginDefaultAdminTransfer}.
     *
     * After calling the function:
     *
     * - `DEFAULT_ADMIN_ROLE` should be granted to the caller.
     * - `DEFAULT_ADMIN_ROLE` should be revoked from the previous holder.
     * - {pendingDefaultAdmin} should be reset to zero values.
     *
     * Requirements:
     *
     * - Only can be called by the {pendingDefaultAdmin}'s `newAdmin`.
     */
    function acceptDefaultAdminTransfer() external;
}
