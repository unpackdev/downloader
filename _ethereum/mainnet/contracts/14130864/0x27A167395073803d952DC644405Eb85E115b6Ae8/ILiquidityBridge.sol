// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface ILiquidityBridge {
    event BMIMigratedToV2(
        address indexed recipient,
        uint256 amountBMI,
        uint256 rewardsBMI,
        uint256 burnedStkBMI
    );
    event MigratedBMIStakers(uint256 migratedCount);
}
