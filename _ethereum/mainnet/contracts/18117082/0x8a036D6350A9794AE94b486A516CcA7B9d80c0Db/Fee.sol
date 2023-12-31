// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title Fee
 * @notice Struct to hold the fee amounts for LP, admin and protocol. Is used in the protocol to 
 *   pass the fee percentages and the total fee amount depending on the context.
 */
struct Fee {
    uint256 lp;
    uint256 admin;
    uint256 protocol;
}
