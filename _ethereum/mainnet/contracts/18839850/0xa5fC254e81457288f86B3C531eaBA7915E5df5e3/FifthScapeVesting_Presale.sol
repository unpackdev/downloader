// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./FifthScapeVestingBase.sol";

contract FifthScapeVesting_Presale is FifthScapeVestingBase {
    uint256 private START = 1734693212;
    uint256 private DURATION = 240 days;
    uint256 private INITIAL_RELEASE_PERCENTAGE = 40;

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
