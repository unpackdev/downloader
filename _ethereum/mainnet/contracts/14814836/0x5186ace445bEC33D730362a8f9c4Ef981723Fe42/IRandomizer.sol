// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRandomizer {
    function random() external view returns (uint256);
    function randomCall() external;
}