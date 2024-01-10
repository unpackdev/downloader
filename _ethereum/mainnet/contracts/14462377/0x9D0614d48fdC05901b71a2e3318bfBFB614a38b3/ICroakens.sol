// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICroakens {
    function burn(address user, uint256 amount) external;
    function approve(address user, uint256 amount) external;
}