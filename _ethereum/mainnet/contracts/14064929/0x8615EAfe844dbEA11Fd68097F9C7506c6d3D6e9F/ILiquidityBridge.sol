// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityBridge {
    event BMIMigratedToV2(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);
    event MigratedBMIStakers(uint256 migratedCount);
}
