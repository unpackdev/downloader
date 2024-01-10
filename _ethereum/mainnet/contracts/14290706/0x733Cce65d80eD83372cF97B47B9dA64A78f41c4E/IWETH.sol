// SPDX-License-Identifier: MIT
pragma solidity  ^0.6.12;

interface IWETH {

    function withdraw(uint) external;
    function deposit() external payable;
    
}
