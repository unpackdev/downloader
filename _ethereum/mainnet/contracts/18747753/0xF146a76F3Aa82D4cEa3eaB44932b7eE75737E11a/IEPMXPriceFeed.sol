// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IEPMXPriceFeed {
    /**
     * @notice Sets the answer for the current round.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param answer The answer to be set with a precision of 8 decimal (USD decimals).
     */
    function setAnswer(int256 answer) external;
}
