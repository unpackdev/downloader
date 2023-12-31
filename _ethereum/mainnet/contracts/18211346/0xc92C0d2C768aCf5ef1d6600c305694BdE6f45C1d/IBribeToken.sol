// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeToken {
    function mint(address to, uint256 amount) external;
    function balanceOf(address who) external view returns (uint256);
    function burn(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
} 