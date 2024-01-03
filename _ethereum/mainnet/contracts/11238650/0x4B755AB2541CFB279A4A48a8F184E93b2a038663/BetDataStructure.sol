pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

contract BetDataStructure {
    uint public claimPercentage = 20;

    struct BetWeek {
        uint total;
        bool concluded;
        address[] betters;
        uint32[] deaths;
        uint32[] infections;
        uint32 finalDeaths;
        uint32 finalInfections;
    }

    mapping(uint => BetWeek) public betWeeks;

    function getBetWeek (uint _weekId) public view returns (
        uint total,
        bool concluded,
        address[] memory betters,
        uint32[] memory deaths,
        uint32[] memory infections,
        uint32 finalDeaths,
        uint32 finalInfections

    ) {
        BetWeek memory betWeek = betWeeks[_weekId];

        total = betWeek.total;
        concluded = betWeek.concluded;
        betters = betWeek.betters;
        deaths = betWeek.deaths;
        infections = betWeek.infections;
        finalDeaths = betWeek.finalDeaths;
        finalInfections = betWeek.finalInfections;
    }
}   