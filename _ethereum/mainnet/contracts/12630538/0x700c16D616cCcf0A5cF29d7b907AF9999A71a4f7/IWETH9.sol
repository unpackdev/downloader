// SPDX-License-Identifier: GNU
pragma solidity 0.7.6;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint value) external returns (bool);
}
