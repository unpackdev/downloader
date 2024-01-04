// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

/**
 * @dev Implementation of the March 19th 2021 to April 5th 2021 March Madness Oracle with Associated Press
 *
 * All interested consumers can freely access the games from the "games" mapping
 * You may also listen for the "SetWinner" event.
 */
contract MarchMadness2021 is Ownable {

    /**
     * @dev Game struct for holding the Game data
     */
    struct Game {
        string id;
        string homeTeam;
        string awayTeam;
        uint winner; // 0: none, 1: home, 2: away
        uint homePoints;
        uint awayPoints;
        uint scheduled;
        uint round;
        /**
         *  @dev round
         *  0: "firstFour"
         *  1: "firstRound"
         *  2: "secondRound"
         *  3: "sweet16"
         *  4: "eliteEight"
         *  5: "finalFour"
         *  6: "nationalChampionship"
         */
    }

    mapping(string => Game) public allGames;
    string public ipfsFullData;

    /**
     *  @dev Event is called whenever a winner is called
     */
    event CallWinner(
        string id,
        string homeTeam,
        string awayTeam,
        uint winner,
        uint homePoints,
        uint awayPoints,
        uint scheduled
    );

    /**
     *  @dev Calls a Winner for a game
     */
    function callWinner(
        uint round,
        string calldata id,
        string calldata homeTeam,
        string calldata awayTeam,
        uint winner,
        uint homePoints,
        uint awayPoints,
        uint scheduled
    )
    external
    onlyOwner
    {
        allGames[id] = Game(id, homeTeam, awayTeam, winner, homePoints, awayPoints, scheduled, round);
        emit CallWinner(id, homeTeam, awayTeam, winner, homePoints, awayPoints, scheduled);
    }

    /**
     *  @dev Returns a specific game based on id
     */
    function getGame(string memory id) public view returns (Game memory){
        return allGames[id];
    }

    /**
     *  @dev Event is called whenever the ipfs hash is updated
     */
    event SetIPFS(string ipfsHash);

    /**
    *   @dev Sets the IPFS hash for the pinned json containing the data for March Madness
    */
    function setIpfsData(string calldata ipfsHash)
    external
    onlyOwner
    {
        ipfsFullData = ipfsHash;
        emit SetIPFS(ipfsHash);
    }
}
