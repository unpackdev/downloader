// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleAirdropper {
    function airdrop(uint256 numberOfTokens, address to) external returns (uint256);
}
