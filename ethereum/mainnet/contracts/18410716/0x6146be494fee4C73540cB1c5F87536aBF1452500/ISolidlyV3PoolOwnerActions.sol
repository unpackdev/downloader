// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface ISolidlyV3PoolOwnerActions {
    /// @notice Set the pool's trading fee (applied to input tokens on all swaps)
    /// @param fee new trading fee in hundredths of a bip, i.e. 1e-6
    function setFee(uint24 fee) external;

    /// @notice Collect the protocol fee accrued to the pool. All fees are to be collected only by
    /// the protocol's Reward Distributor, which processes claims for liquidity providers and protocol
    /// voters after verifying them against a periodically updated merkle root
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}
