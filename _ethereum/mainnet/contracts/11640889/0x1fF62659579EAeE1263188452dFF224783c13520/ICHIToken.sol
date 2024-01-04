pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT


interface ICHIToken {
    function freeFromUpTo(address _addr, uint256 _amount) external returns (uint256);
}