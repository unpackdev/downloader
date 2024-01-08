// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./InitializableStore.sol";
import "./ManagerRoleStore.sol";
import "./ERC20Store.sol";
import "./PausableStore.sol";
import "./FreezableStore.sol";

struct XenoERC20Store {
    InitializableStore initializable;
    ManagerRoleStore managerRole;
    ERC20Store erc20;
    PausableStore pausable;
    FreezableStore freezable; // the slot taken by the struct of this is the last slotted item
}