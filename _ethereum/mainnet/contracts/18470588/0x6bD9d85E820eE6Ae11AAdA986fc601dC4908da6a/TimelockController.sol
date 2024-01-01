// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./TimelockControllerUpgradeable.sol";
import "./Initializable.sol";

contract TimelockController is Initializable, TimelockControllerUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 minDelay_,
        address[] memory proposers_,
        address[] memory executors_,
        address admin_
    ) external initializer {
        __TimelockController_init(minDelay_, proposers_, executors_, admin_);
    }
}
