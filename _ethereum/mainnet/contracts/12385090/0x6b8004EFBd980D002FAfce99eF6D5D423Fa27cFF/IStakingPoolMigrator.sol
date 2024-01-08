// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakingPoolMigrator {
    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external returns (address);
}
