// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRoles {

    /*
        @notice Give or remove accounts the admin role.
        @dev Can be called only by contract manager.
        @param account The target account.
        @param admin True if the target account will be assigned the role of admin, false if it is revoked.
    */
    function setAdmin(address account, bool admin) external;

    /*
        @notice Revokes the admin role from the caller.
    */
    function renounceAdmin() external;

    /*
        @notice Sets the target account as the new contract manager.
        @dev Can be invoked only by the contract manager.
        @param account The address of the target account.
    */
    function updateManager(address account) external;

    /*
        @notice Checks if an account has the admin role or not.
        @param account The address of the target account.
        @return True if the target account has the admin role, false otherwise.
    */
    function isAccountAdmin(address account) external view returns(bool);

    /*
        @notice Emitted when ad admin is crated or removed.
        @param account The target account.
        @param admin Set to true if the target account will be an admin, false otherwise.
    */
    event UpdatedAdmin(address account, bool indexed admin);

    /*
        @notice Emitted when the new contract manager is set.
        @param manager The target account.
    */
    event UpdatedContractManager(address manager);
}
