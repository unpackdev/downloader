// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * IMPORTANT: Structs are append-only
 * IMPORTANT: We shouldn't store arrays of structs
 */

/**
 * Once created, a ValhallaPlanet should never change
 */
struct ValhallaPlanet {
    address originalWinner;
    uint8 roundId;
    uint8 level;
    uint8 rank;
    uint8 planetType;
}

contract ValhallaStorageV1 {
    /**
     * IMPORTANT: Contract upgrades should only ever append to storage.
     */
    address public adminAddress;

    mapping(uint256 => ValhallaPlanet) public planets;

    mapping(uint8 => mapping(address => uint8)) public gameWinnerRanks; // roundId => player => rank
    mapping(uint8 => mapping(address => bool)) public gameWinnerCanClaim; // roundId => player => can claim
    mapping(uint8 => mapping(address => uint8)) public specialWinnerLevels; // roundId => player => level
    mapping(uint8 => mapping(address => bool)) public specialWinnerCanClaim; // roundId => player => can claim
}
