// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ILpSafeFunder {
    // struct representing the pool and the amount to move when funding an account
    // poolId represents the pool to move funds from
    // amount represents the amount to move when funding
    struct PoolAmount {
        bytes32 poolId;
        uint256 amount;
    }

    function fundLpSafe(PoolAmount[] calldata poolAmounts) external;

    function withdrawFromLpSafe(PoolAmount[] calldata poolAmounts) external;
}
