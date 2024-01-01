//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermController is an interface that defines events and functions of the Controller contract.
interface ITermControllerEvents {
    /// @notice Event emitted when the treasury wallet address for Term Finance is updated.
    /// @param oldTreasuryAddress previous address of Treasury Wallet
    /// @param newTreasuryAddress new/current address of Treasury Wallet
    event TreasuryAddressUpdated(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );

    /// @notice Event emitted when the protocol reserve wallet address for Term Finance is updated.
    /// @param oldProtocolReserveAddress previous address of protocol reserve
    /// @param newProtocolReserveAddress new/current address of protocol reserve
    event ProtocolReserveAddressUpdated(
        address oldProtocolReserveAddress,
        address newProtocolReserveAddress
    );
}
