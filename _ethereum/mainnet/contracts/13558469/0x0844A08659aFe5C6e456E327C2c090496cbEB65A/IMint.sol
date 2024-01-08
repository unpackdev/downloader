// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMint {
    function mint(uint256 numberOfTokens) external payable;
}
