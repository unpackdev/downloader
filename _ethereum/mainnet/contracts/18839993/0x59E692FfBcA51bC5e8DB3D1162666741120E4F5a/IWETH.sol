// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IWETH {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}