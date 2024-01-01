// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IswETH {
    function swETHToETHRate() external view returns (uint256);
    function deposit() external payable;
}
