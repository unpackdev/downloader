// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./Multicall.sol";
import "./Ownable.sol";
import "./IHeroManager.sol";
import "./ILobbyManager.sol";

contract DataProcessor is Multicall, Ownable {
  IHeroManager public heroManager;
  ILobbyManager public lobbyManager;

  constructor(address hmAddr, address lmAddr) {
    heroManager = IHeroManager(hmAddr);
    lobbyManager = ILobbyManager(lmAddr);
  }

  function getPlayerHeroesOnLobby(uint256 lobbyId, address player)
    public
    view
    returns (uint256[] memory)
  {
    return lobbyManager.getPlayerHeroesOnLobby(lobbyId, player);
  }

  function getLobbyHeroes(uint256 lobbyId)
    external
    view
    returns (
      address,
      uint256[] memory,
      address,
      uint256[] memory
    )
  {
    (, , address host, address client, , , , , , , ) = lobbyManager.lobbies(
      lobbyId
    );
    return (
      host,
      getPlayerHeroesOnLobby(lobbyId, host),
      client,
      getPlayerHeroesOnLobby(lobbyId, client)
    );
  }

  function getLobbyPower(uint256 lobbyId)
    external
    view
    returns (
      address,
      uint256,
      address,
      uint256
    )
  {
    (, , address host, address client, , , , , , , ) = lobbyManager.lobbies(
      lobbyId
    );
    uint256 hostPower = lobbyManager.powerHistory(lobbyId, host);
    uint256 clientPower = lobbyManager.powerHistory(lobbyId, client);

    return (host, hostPower, client, clientPower);
  }

  function getHeroesPower(uint256[] memory heroes)
    public
    view
    returns (uint256)
  {
    return lobbyManager.getHeroesPower(heroes);
  }

  function getActiveLobbies(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host != myAddr) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host != myAddr) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getMyLobbies(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host == myAddr) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        ,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (finishedAt == 0 && capacity == lobbyCapacity && host == myAddr) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getMyHistory(address myAddr, uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        address client,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (
        finishedAt > 0 &&
        capacity == lobbyCapacity &&
        (host == myAddr || client == myAddr)
      ) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (
        ,
        ,
        address host,
        address client,
        ,
        uint256 capacity,
        ,
        uint256 finishedAt,
        ,
        ,

      ) = lobbyManager.lobbies(i);
      if (
        finishedAt > 0 &&
        capacity == lobbyCapacity &&
        (host == myAddr || client == myAddr)
      ) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function getAllHistory(uint256 lobbyCapacity)
    external
    view
    returns (uint256[] memory)
  {
    uint256 count;

    uint256 totalLobbies = lobbyManager.totalLobbies();
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (, , , , , uint256 capacity, , uint256 finishedAt, , , ) = lobbyManager
        .lobbies(i);
      if (finishedAt > 0 && capacity == lobbyCapacity) {
        count++;
      }
    }

    uint256 baseIndex = 0;
    uint256[] memory result = new uint256[](count);
    for (uint256 i = 1; i <= totalLobbies; i++) {
      (, , , , , uint256 capacity, , uint256 finishedAt, , , ) = lobbyManager
        .lobbies(i);
      if (finishedAt > 0 && capacity == lobbyCapacity) {
        result[baseIndex] = i;
        baseIndex++;
      }
    }

    return result;
  }

  function setHeroManager(address hmAddr) external onlyOwner {
    heroManager = IHeroManager(hmAddr);
  }

  function setLobbyManager(address lmAddr) external onlyOwner {
    lobbyManager = ILobbyManager(lmAddr);
  }
}
