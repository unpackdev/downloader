// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IAdminRegistry {
    function isSuperAdminAccess(address admin) external view returns (bool);
}
