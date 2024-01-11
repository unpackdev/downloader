// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./TimelockController.sol";


contract Timelock is TimelockController {

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors) {
    }
}
