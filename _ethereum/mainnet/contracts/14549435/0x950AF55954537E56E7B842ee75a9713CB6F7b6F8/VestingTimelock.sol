// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TimelockControllerUpgradeable.sol";

/**
 * vesting timelock
 */
contract VestingTimelock is TimelockControllerUpgradeable {

    string public constant flag = "Treasury";

    function initialize(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) public initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
    
}