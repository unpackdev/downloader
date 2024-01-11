// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Composable.sol";

contract IngameItems is Composable {
    mapping(address => uint256) gemMap;
    uint256 public gemCount;

    mapping(address => uint256) totemMap;
    uint256 public totemCount;

    mapping(address => uint256) ghostMap;
    uint256 public ghostCount;

    mapping(uint256 => mapping(address => uint256)) gemWinsByMonsterBattle; 
    mapping(uint256 => mapping(address => uint256)) totemWinsByMonsterBattle;
    mapping(uint256 => mapping(address => uint256)) ghostWinsByMonsterBattle;

    function getGemWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return gemWinsByMonsterBattle[battleId][winner];
    }

    function getTotemWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return totemWinsByMonsterBattle[battleId][winner];
    }

    function getGhostWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return ghostWinsByMonsterBattle[battleId][winner];
    }

    function addGemToPlayer(uint256 battleId, address _address) external onlyComponent {
        gemWinsByMonsterBattle[battleId][_address] += 1;
        gemMap[_address] += 1;
        gemCount++;
    }

    function removeGemFromPlayer(address _address) external onlyComponent {
        if (gemMap[_address] > 0) {
            gemMap[_address] -= 1;
            gemCount--;
        }
    }

    function moveGem(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (gemMap[fromAddress] > 0) {
            gemMap[fromAddress] -= 1;
            gemMap[toAddress] += 1;
        }
    }

    function adminAddGemToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        gemWinsByMonsterBattle[battleId][_address] += 1;
        gemMap[_address] += 1;
        gemCount++;
    }

    function adminAddGemToPlayer(address _address) external onlyOwner {
        gemMap[_address] += 1;
        gemCount++;
    }

    function viewGemCountForPlayer(address owner) public view returns (uint256){
        return gemMap[owner];
    }

    // Totems

    function addTotemToPlayer(uint256 battleId, address _address) external onlyComponent {
        totemWinsByMonsterBattle[battleId][_address] += 1;
        totemMap[_address] += 1;
        totemCount++;
    }

    function removeTotemFromPlayer(address _address) external onlyComponent {
        if (totemMap[_address] > 0) {
            totemMap[_address] -= 1;
            totemCount--;
        }
    }

    function moveTotem(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (totemMap[fromAddress] > 0) {
            totemMap[fromAddress] -= 1;
            totemMap[toAddress] += 1;
        }
    }

    function adminAddTotemToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        totemWinsByMonsterBattle[battleId][_address] += 1;
        totemMap[_address] += 1;
        totemCount++;
    }

    function adminAddTotemToPlayer(address _address) external onlyOwner {
        totemMap[_address] += 1;
        totemCount++;
    }

    function viewTotemCountForPlayer(address owner) public view returns (uint256){
        return totemMap[owner];
    }

    // Ghost

    function addGhostToPlayer(uint256 battleId, address _address) external onlyComponent {
        ghostWinsByMonsterBattle[battleId][_address] += 1;
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function removeGhostFromPlayer(address _address) external onlyComponent {
        if (ghostMap[_address] > 0) {
            ghostMap[_address] -= 1;
            ghostCount--;
        }
    }

    function moveGhost(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (ghostMap[fromAddress] > 0) {
            ghostMap[fromAddress] -= 1;
            ghostMap[toAddress] += 1;
        }
    }

    function adminAddGhostToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        ghostWinsByMonsterBattle[battleId][_address] += 1;
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function adminAddGhostToPlayer(address _address) external onlyOwner {
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function viewGhostCountForPlayer(address owner) public view returns (uint256){
        return ghostMap[owner];
    }

    // All
    function viewAllCountsForPlayer(address owner) public view returns (uint256[] memory){
        uint256[] memory arr = new uint256[](3);
        arr[0] = gemMap[owner];
        arr[1] = totemMap[owner];
        arr[2] = ghostMap[owner];
        return arr;
    }

    function viewAllWinsForPlayerInBattle(uint256 battleId, address owner) public view returns (uint256[] memory){
        uint256[] memory arr = new uint256[](3);
        arr[0] = gemWinsByMonsterBattle[battleId][owner];
        arr[1] = totemWinsByMonsterBattle[battleId][owner];
        arr[2] = ghostWinsByMonsterBattle[battleId][owner];
        return arr;
    }

}
