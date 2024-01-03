// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";

/**
 * @dev Implementation of the January 5th, 2021 Senate Run-off Oracle with Associated Press
 *
 * All interested consumers can freely access the race calls from the "winners" mapping
 * You may also listen for the "SetWinner" event.
 */
contract Jan2021SenateRunoffs is Ownable {
    /**
     *  @dev Event is called whenever a winner is called
     */
    event SetWinner(string positionName, string winnerLastName);

    /**
     *  @dev Where the senate run-off winners are stored. Mapping position to the winner's last name.
     * "U.S. Senate Class II": "Perdue"
     * "U.S. Senate Class III": "Loeffler"
     */
    mapping(string => string) public winners;

    /**
     *  @dev Only callable by AP. Used to make a race call
     */
    function setWinner(string memory positionName, string memory winnerLastName)
        public
        onlyOwner
    {
        winners[positionName] = winnerLastName;
        emit SetWinner(positionName, winnerLastName);
    }
}
