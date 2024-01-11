// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TimelockControllerUpgradeable.sol";

/**
 * vault timelock
 */
contract VaultTimelock is TimelockControllerUpgradeable {

    string public constant flag = "Staking";

    function initialize(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) public initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
    
}