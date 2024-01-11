// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ILobbyManager {
  function lobbies(uint256 lobbyId)
    external
    view
    returns (
      bytes32 name,
      bytes32 avatar,
      address host,
      address client,
      uint256 id,
      uint256 capacity,
      uint256 startedAt,
      uint256 finishedAt,
      uint256 winner,
      uint256 fee,
      uint256 rewards
    );

  function lobbyHeroes(
    uint256 lobbyId,
    address player,
    uint256 index
  ) external view returns (uint256);

  function powerHistory(uint256 lobbyId, address player)
    external
    view
    returns (uint256);

  function getPlayerHeroesOnLobby(uint256 lobbyId, address player)
    external
    view
    returns (uint256[] memory);

  function getHeroesPower(uint256[] memory heroes)
    external
    view
    returns (uint256);

  function totalLobbies() external view returns (uint256);
}
