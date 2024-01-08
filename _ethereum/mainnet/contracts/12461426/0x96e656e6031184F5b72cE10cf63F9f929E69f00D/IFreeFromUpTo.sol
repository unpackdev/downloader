// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @dev interface to allow the burning of gas tokens from an address
*/
interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}