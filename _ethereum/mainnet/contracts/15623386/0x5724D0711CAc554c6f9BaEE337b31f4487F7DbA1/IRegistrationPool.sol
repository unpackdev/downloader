// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRegistrationPool {
    function initalizePool(uint256 blockNum, uint256 reward) external;
    function deliverReward(uint256 round, uint256 amount) external;
    function gainPonts(address receiver, uint256 point) external returns(uint256);
}