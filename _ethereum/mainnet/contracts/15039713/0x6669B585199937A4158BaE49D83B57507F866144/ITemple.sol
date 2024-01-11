// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITemple {
    function stake(uint256 id) external returns (bool);
    function updateClaimable(uint256 id) external;
    function claim(uint256 id) external returns (uint256);
    function getInRetreat(uint256 id) external;
    function unstake(uint256 id, bool isWearing) external returns (uint256);
}
