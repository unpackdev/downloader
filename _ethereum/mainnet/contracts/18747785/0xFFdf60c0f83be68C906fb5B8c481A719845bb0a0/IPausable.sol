// Copyright (c) 2016-2023 zOS Global Limited and contributors
// SPDX-License-Identifier: MIT

// Interface for OpenZeppelin's Pausable contract from https://github.com/OpenZeppelin/openzeppelin-contracts/
pragma solidity ^0.8.18;

interface IPausable {
    /**
     * @dev Triggers stopped state.
     * This function can only be called by an address with the EMERGENCY_ADMIN role.
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     * This function can only be called by an address with the SMALL_TIMELOCK_ADMIN or MEDIUM_TIMELOCK_ADMIN role depending on the contract.
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;
}
