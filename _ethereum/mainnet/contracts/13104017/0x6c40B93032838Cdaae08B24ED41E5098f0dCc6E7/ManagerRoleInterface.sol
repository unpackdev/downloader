// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ManagerRoleInterface {    

    /**
     * @dev Returns true if `account` has the manager role, and false otherwise.
     */
    function isManager(address account) external view returns (bool);

    /**
     * @dev Give the manager role to `account`.
     */
    function addManager(address account) external;

    /**
     * @dev Renounce the manager role for the caller.
     */
    function renounceManager() external;

}