// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGuardVault {
    function initGuardianVault(uint tokenId, uint value) external payable;

    function forGuard() external payable;
}