// SPDX-License-Identifier: MIT

import "./TokenTimelock.sol";


pragma solidity 0.7.5;
pragma abicoder v2;

contract AUG2023Timelock is TokenTimelock {
    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_
    ) TokenTimelock(token_, beneficiary_, releaseTime_) {}
}
