// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IWETH9 {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
}