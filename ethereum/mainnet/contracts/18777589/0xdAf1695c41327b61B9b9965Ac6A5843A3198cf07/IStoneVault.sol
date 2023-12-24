// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IStoneVault {
    function deposit() external payable returns (uint256 mintAmount);
}
