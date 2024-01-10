// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStakedAave {
    function stake(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}