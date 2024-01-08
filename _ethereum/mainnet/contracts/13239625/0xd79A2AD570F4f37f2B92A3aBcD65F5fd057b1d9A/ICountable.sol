// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

// Expose the ICountable interface
interface ICountable {
    function count() external returns (uint256);
}