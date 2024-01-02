//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRandomizer {
    function getRandomNumber(address input0, uint256 input1, uint256 input2) external returns (uint256 result);
}