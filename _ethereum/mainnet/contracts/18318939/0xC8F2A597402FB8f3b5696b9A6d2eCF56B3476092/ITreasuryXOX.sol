// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITreasuryXOX {
    function preSaleXOX(address from, address ref, uint256 amount, uint256 rewardPercent, uint256 round) external returns (uint256);
    function seedSale(uint256 amount) external;
}
