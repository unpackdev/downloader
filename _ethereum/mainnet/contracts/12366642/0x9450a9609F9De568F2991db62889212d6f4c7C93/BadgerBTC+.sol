// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./CompositePlus.sol";

/**
 * @title BadgerBTC+ token contract.
 * 
 * BadgerBTC+ is a composite plus that is backed by single pluses which are backed by
 * Badger's Sett.
 */
contract BadgerBTCPlus is CompositePlus {

    /**
     * @dev Initializes the BadgerBTC+ contract.
     */
    function initialize() public initializer {
        CompositePlus.initialize("Badger BTC Plus", "BadgerBTC+");
    }
}