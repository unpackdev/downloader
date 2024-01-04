// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";

/**
 * @dev Implementation of the February 7th, 2021 Super Bowl LV Oracle with Associated Press
 *
 * All interested consumers can freely access the superbowl results from the "winner"
 * You may also listen for the "SetWinner" event.
 */
contract SuperBowlLV is Ownable {
    /**
     *  @dev Event is called whenever a winner is called
     */
    event SetWinner(string winnerLastName);

    /**
     *  @dev Where the Super Bowl LV winner is stored.
     * "Chiefs"
     * "Buccaneers"
     */
    string public winner;

    /**
     *  @dev Only callable by AP. Used to make a superbowl winner call
     */
    function setWinner(string memory winningTeam)
        public
        onlyOwner
    {
        winner = winningTeam;
        emit SetWinner(winningTeam);
    }
}
