// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./TimelockController.sol";

import "./Errors.sol";

contract Timelock is TimelockController {
    constructor(
        uint256 minDelay,
        address admin,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {
        // revoke admin role from msg.sender
        revokeRole(TIMELOCK_ADMIN_ROLE, msg.sender);

        // setup admin role
        _setupRole(TIMELOCK_ADMIN_ROLE, admin);
    }
}
