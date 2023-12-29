// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./FifthScapeVestingBase.sol";

contract FifthScapeVesting_Development is FifthScapeVestingBase {
    uint256 private START = 1734693212;
    uint256 private DURATION = 730 days;
    uint256 private INITIAL_RELEASE_PERCENTAGE = 25;

    constructor(
        address _token,
        address _owner
    )
        FifthScapeVestingBase(
            _token,
            START,
            DURATION,
            INITIAL_RELEASE_PERCENTAGE,
            _owner
        )
    {}
}
