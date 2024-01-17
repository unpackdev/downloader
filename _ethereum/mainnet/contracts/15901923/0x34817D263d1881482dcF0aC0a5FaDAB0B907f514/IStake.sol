// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStake {
    function deposit(address from, uint256 amount) external;

    function withdraw(address to, uint256 amount) external;

    function stakePrice() external returns (uint256);
}
