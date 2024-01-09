// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 value) external;

    function transfer(address to, uint256 value) external returns (bool);
}
