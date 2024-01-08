// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILockedOwner {
    function burnTokens(uint256 amount) external;
}