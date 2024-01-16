// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for the VestingEscrow contract.
 */
interface IVestingEscrow {
    /**
     * @dev vests `vestingAmount` of Neats for a `vestee` of a `vesteeType`.
     */
    function vest(
        address vestee,
        uint256 tokenAmount,
        uint256 cliffDays,
        uint256 initiallyAvailableTokens,
        uint256 periodMonths
    ) external;
}
