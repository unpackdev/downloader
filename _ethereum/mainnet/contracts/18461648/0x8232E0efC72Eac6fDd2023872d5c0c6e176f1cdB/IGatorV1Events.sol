// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IGatorV1Events {
    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param name The owner of the position and recipient of any minted liquidity
    event e_addGater(address gateAddress, bytes32 name);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param name The owner of the position and recipient of any minted liquidity
    event e_updateGatebyGator(address gateAddress, bytes32 name);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity

    event e_unlockGatebyGater(address gateAddress);
    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity

    event e_lockGatebyGater(address gateAddress);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param marketoraddress The owner of the position and recipient of any minted liquidity
    event e_delGatebyMarketor(address gateAddress, address marketoraddress);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param name The owner of the position and recipient of any minted liquidity
    /// @param marketoraddress The owner of the position and recipient of any minted liquidity
    event e_updateGatebyMarketor(
        address gateAddress,
        bytes32 name,
        address marketoraddress
    );

    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param marketoraddress The address that minted the liquidity

    event e_unlockGatebyMarketor(address gateAddress, address marketoraddress);
    /// @notice Emitted when liquidity is minted for a given position
    /// @param gateAddress The address that minted the liquidity
    /// @param marketoraddress The address that minted the liquidity

    event e_lockGatebyMarketor(address gateAddress, address marketoraddress);

    event e_addGaterDetail(address gateaddress);

    event e_updateGater(address, bytes32);

    event e_updateGaterDetail(address);
}
