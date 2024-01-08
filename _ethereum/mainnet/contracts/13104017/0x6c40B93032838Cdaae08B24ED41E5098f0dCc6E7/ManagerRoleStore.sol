// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./RolesStore.sol";

/* STORAGE LAYOUT */

struct ManagerRoleStore {
    bool initialized;
    Role managers;
}