// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct Record {
    uint64 playerId;
    uint48 roundsWon;
    uint48 seriesWon;
    uint48 roundsLost;
    uint48 seriesLost;
    uint128 wagers;
    uint128 profits;
    uint40[] games;
}

/// @title Interface for Recorder contract
interface IRecorder {
    event SetRecord(
        address indexed _player,
        uint64 indexed _playerId,
        uint40 indexed _gameId,
        uint48 roundsWon,
        uint48 seriesWon,
        uint48 roundsLost,
        uint48 seriesLost,
        uint128 _wagers,
        uint128 _profits
    );

    function adjustRake(uint256 _pot, uint256 _rake) external pure returns (uint256);

    function getGameIds(address _player) external view returns (uint40[] memory);

    function setRecord(
        uint40 _gameId,
        uint72 _pot,
        uint8 _totalRounds,
        uint8 _currentRound,
        address _winner,
        address _loser
    ) external;

    function weiToEth(uint256 _weiAmount) external pure returns (string memory);
}
