// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet ISuperAdmin
 * @author Dollet Team
 * @notice Interface for managing the super admin role.
 */
interface ISuperAdmin {
    /**
     * @notice Logs the information about nomination of a potential super admin.
     * @param _potentialSuperAdmin The address of the potential super admin.
     */
    event SuperAdminNominated(address _potentialSuperAdmin);

    /**
     * @notice Logs the information when the super admin role is transferred.
     * @param _oldSuperAdmin The address of the old super admin.
     * @param _newSuperAdmin The address of the new super admin.
     */
    event SuperAdminChanged(address _oldSuperAdmin, address _newSuperAdmin);

    /**
     * @notice Transfers the super admin role to a potential super admin address using pull-over-push pattern.
     * @param _superAdmin An address of a potential super admin.
     */
    function transferSuperAdmin(address _superAdmin) external;

    /**
     * @notice Accepts the super admin role by a potential super admin.
     */
    function acceptSuperAdmin() external;

    /**
     * @notice Returns the address of the super admin.
     * @return The address of the super admin.
     */
    function superAdmin() external view returns (address);

    /**
     * @notice Returns the address of the potential super admin.
     * @return The address of the potential super admin.
     */
    function potentialSuperAdmin() external view returns (address);

    /**
     * @notice Checks if the caller is a valid super admin.
     * @param caller The address to check.
     */
    function isValidSuperAdmin(address caller) external view;
}

/**
 * @title Dollet IAdminStructure
 * @author Dollet Team
 * @notice Interface for managing admin roles.
 */
interface IAdminStructure is ISuperAdmin {
    /**
     * @notice Logs the information when an admin is added.
     * @param admin The address of the added admin.
     */
    event AddedAdmin(address admin);

    /**
     * @notice Logs the information when an admin is removed.
     * @param admin The address of the removed admin.
     */
    event RemovedAdmin(address admin);

    /**
     * @notice Adds multiple addresses as admins.
     * @param _admins The addresses to add as admins.
     */
    function addAdmins(address[] calldata _admins) external;

    /**
     * @notice Removes multiple addresses from admins.
     * @param _admins The addresses to remove from admins.
     */
    function removeAdmins(address[] calldata _admins) external;

    /**
     * @notice Checks if the caller is a valid admin.
     * @param caller The address to check.
     */
    function isValidAdmin(address caller) external view;

    /**
     * @notice Checks if an account is an admin.
     * @param account The address to check.
     * @return A boolean indicating if the account is an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @notice Returns all the admin addresses.
     * @return An array of admin addresses.
     */
    function getAllAdmins() external view returns (address[] memory);
}
