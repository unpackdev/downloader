// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface ITemporaryAdminStructure {
    /**
     * @notice Transfers the super admin role to a potential super admin address using pull-over-push pattern.
     * @param _potentialSuperAdmin An address of a potential super admin.
     */
    function transferSuperAdmin(address _potentialSuperAdmin) external;

    /**
     * @notice Accepts the super admin role by a potential super admin.
     */
    function acceptSuperAdmin() external;

    /**
     * @notice Checks if the caller is a valid admin.
     * @param _caller The address of the caller to check.
     */
    function isValidAdmin(address _caller) external view;

    /**
     * @notice Checks if the caller is a valid super admin.
     * @param _caller The address of the caller to check.
     */
    function isValidSuperAdmin(address _caller) external view;

    /**
     * @notice Retrieves all the admin addresses.
     * @return _adminsList An array of admins' addresses.
     */
    function getAllAdmins() external view returns (address[] memory _adminsList);
}
