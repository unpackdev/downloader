// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./TimelockControllerUpgradeable.sol";

contract CollateralManagerTimelock is TimelockControllerUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize (
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin
    ) public initializer {
        __TimelockController_init(_minDelay, _proposers, _executors, _admin);
    }
}