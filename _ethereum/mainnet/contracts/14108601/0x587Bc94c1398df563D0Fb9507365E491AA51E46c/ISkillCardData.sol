// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ISkillCardData {
    function uploadData(uint256 tokenID, string calldata name, uint256 rank, uint256 level, uint256 deadline) external;
}