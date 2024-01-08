// contracts/SchnoodleTimelockFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SchnoodleTimelock.sol";
import "./Clones.sol";

contract SchnoodleTimelockFactory {
    address immutable schnoodleTimelock;

    constructor() {
        schnoodleTimelock = address(new SchnoodleTimelock());
    }

    function create(IERC20Upgradeable token, address beneficiary, uint256 releaseTime) external returns (address) {
        address clone = Clones.clone(schnoodleTimelock);
        SchnoodleTimelock(clone).initialize(token, beneficiary, releaseTime);
        return clone;
    }
}
