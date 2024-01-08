// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;
pragma abicoder v2;

import "./TimelockController.sol";

contract Timelock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) TimelockController(minDelay, proposers,executors ) public {

    }
}
