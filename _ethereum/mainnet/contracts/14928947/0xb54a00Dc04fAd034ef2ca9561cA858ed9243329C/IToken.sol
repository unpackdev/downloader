// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function balanceOf(address owner) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
}