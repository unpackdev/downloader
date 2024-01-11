// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


interface IGhostMemoriesStorage {
    function isStorageContract() external pure returns (bool);

    function hasMemory(uint256 _tokenId) external view returns (bool);

    function getChosenMemory(uint256 _tokenId) external view returns (string memory);

    function getMemoryType(uint256 _tokenId) external view returns (uint256);
}
