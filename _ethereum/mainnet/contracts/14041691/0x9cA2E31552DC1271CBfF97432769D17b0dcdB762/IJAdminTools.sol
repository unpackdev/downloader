// SPDX-License-Identifier: MIT
/**
 * Created on 2021-05-16
 * @summary: Admin Tools Interface
 * @author: Jibrel Team
 */
pragma solidity 0.8.8;

interface IJAdminTools {
    function isAdmin(address account) external view returns (bool);
    function addAdmin(address account) external;
    function removeAdmin(address account) external;
    function renounceAdmin() external;

    event AdminAdded(address account);
    event AdminRemoved(address account);
}