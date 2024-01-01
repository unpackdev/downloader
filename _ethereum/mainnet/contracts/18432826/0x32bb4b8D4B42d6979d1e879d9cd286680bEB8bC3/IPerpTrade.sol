// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPerpTrade {
    function execute(uint256 command, bytes calldata data, bool isOpen) external payable;
}
