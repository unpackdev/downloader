// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governed.sol";
import "./Bank.sol";

/**
 * @title Contract tracking deaths of Macabris tokens
 */
contract Reaper is Governed {

    // Bank contract
    Bank public bank;

    // Mapping from token ID to time of death
    mapping (uint256 => int64) private _deaths;

    /**
     * @dev Emitted when a token is marked as dead
     * @param tokenId Token ID
     * @param timeOfDeath Time of death (unix timestamp)
     */
    event Death(uint256 indexed tokenId, int64 timeOfDeath);

    /**
     * @dev Emitted when a previosly dead token is marked as alive
     * @param tokenId Token ID
     */
    event Resurrection(uint256 indexed tokenId);

    /**
     * @param governanceAddress Address of the Governance contract
     *
     * Requirements:
     * - Governance contract must be deployed at the given address
     */
    constructor(address governanceAddress) Governed(governanceAddress) {}

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of Bank contract
     *
     * Requirements:
     * - the caller must have the boostrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Marks token as dead and sets time of death
     * @param tokenId Token ID
     * @param timeOfDeath Tome of death (unix timestamp)
     *
     * Requirements:
     * - the caller must have permission to manage deaths
     * - `timeOfDeath` can't be 0
     *
     * Note that tokenId doesn't have to be minted in order to be marked dead.
     *
     * Emits {Death} event
     */
    function markDead(uint256 tokenId, int64 timeOfDeath) external canManageDeaths(msg.sender) {
        require(timeOfDeath != 0, "Time of death of 0 represents an alive token");
        _deaths[tokenId] = timeOfDeath;

        bank.onTokenDeath(tokenId);
        emit Death(tokenId, timeOfDeath);
    }

    /**
     * @dev Marks token as alive
     * @param tokenId Token ID
     *
     * Requirements:
     * - the caller must have permission to manage deaths
     * - `tokenId` must be currently marked as dead
     *
     * Emits {Resurrection} event
     */
    function markAlive(uint256 tokenId) external canManageDeaths(msg.sender) {
        require(_deaths[tokenId] != 0, "Token is not dead");
        _deaths[tokenId] = 0;

        bank.onTokenResurrection(tokenId);
        emit Resurrection(tokenId);
    }

    /**
     * @dev Returns token's time of death
     * @param tokenId Token ID
     * @return Time of death (unix timestamp) or zero, if alive
     *
     * Note that any tokenId could be marked as dead, even not minted or not existant one.
     */
    function getTimeOfDeath(uint256 tokenId) external view returns (int64) {
        return _deaths[tokenId];
    }
}
