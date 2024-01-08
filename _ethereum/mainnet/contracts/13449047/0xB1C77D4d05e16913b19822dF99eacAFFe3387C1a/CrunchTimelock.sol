// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./TokenTimelock.sol";

import "./CrunchToken.sol";

contract CrunchTimelock is TokenTimelock {
    constructor(
        CrunchToken crunch,
        address beneficiary,
        uint256 releaseDuration
    ) TokenTimelock(crunch, beneficiary, block.timestamp + releaseDuration) {}
}
