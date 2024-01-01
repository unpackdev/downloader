// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IBitcoin {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external returns (uint8);
}
