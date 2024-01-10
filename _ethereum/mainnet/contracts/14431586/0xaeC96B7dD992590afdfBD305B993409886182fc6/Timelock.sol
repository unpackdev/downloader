// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./TimelockController.sol";

contract HydraTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {}
}
