// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TokenTimelock.sol";

/***
 * @notice Token Vault for ManageLife Token ($MLIFE)
 * @author https://managelife.co
 */
contract ManageLifeTokenTimeLock is TokenTimelock {
    constructor(
        IERC20 token,
        address beneficiary,
        uint256 releaseTime
    ) TokenTimelock(token, beneficiary, releaseTime) {}
}
