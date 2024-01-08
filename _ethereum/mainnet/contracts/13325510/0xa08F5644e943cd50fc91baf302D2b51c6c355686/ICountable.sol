// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

// Expose the ICountable interface
interface ICountable {
    function holderCount() external returns (uint256);
}