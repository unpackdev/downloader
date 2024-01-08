// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRewardToken {
    function balanceOf(address owner) external view returns (uint);
    function take() external view returns (uint);
    function funds(address user) external view returns (uint);
    function mint(address to, uint value) external returns (bool);
}