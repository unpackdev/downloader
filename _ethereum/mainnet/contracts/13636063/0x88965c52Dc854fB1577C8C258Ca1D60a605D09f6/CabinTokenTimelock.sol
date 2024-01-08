// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./TokenTimelock.sol";
import "./IERC20.sol";

contract CabinTokenTimelock is TokenTimelock {
    constructor(
        address token,
        address beneficiary,
        uint256 releaseTime
    ) TokenTimelock(IERC20(token), beneficiary, releaseTime) {}
}
