// SPDX-License-Identifier: MIIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address addr) external view returns (uint256);
}