//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBPool {

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getBalance(address token) external view returns (uint);
}