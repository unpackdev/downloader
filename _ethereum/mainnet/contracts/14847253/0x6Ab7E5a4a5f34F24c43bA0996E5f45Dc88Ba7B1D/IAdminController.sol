// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAdminController {
    function setAdmins(address to, bool value) external;
    function isAdmin(address) external view returns (bool);
}