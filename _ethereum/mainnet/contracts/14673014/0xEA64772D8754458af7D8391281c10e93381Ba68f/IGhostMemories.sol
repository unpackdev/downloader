// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


interface IGhostMemories {

    function getMemoryType() external view returns (string memory);

    function getMemoryByGhostId(uint256 _ghostId) external view returns (string memory);

    function getMemoryAndFlashbackByGhostId(uint256 _ghostId) external view returns (string memory);
}
