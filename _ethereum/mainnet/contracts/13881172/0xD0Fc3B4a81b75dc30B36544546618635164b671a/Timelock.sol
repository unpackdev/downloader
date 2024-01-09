// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "./TimelockControllerUpgradeable.sol";

contract Timelock is TimelockControllerUpgradeable {
    function initialize(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) public initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
}
