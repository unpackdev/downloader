// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a vault
/// @notice Contains all events emitted by the vault
interface IVaultEvents {

    /// @notice Emitted when user deposit token in vault
    /// @param user The address that deposited token in vault
    /// @param share0 The share token amount corresponding to the deposit
    /// @param share1 The share token amount corresponding to the deposit
    /// @param amount0 The amount of token0 want to deposit
    /// @param amount1 The amount of token1 want to deposit
    event Deposit(
        address indexed user,
        uint256 share0,
        uint256 share1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when user withdraw their share in vault
    /// @param user The address that withdraw share in vault
    /// @param share0 The amount share to withdraw
    /// @param share1 The amount share to withdraw
    /// @param amount0 How much token0 was taken out by user
    /// @param amount1 How much token1 was taken out by user
    event Withdraw(
        address indexed user,
        uint256 share0,
        uint256 share1,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees collected from uniV3
    /// @param feesFromPool0 How much token0 was collected
    /// @param feesFromPool1 How much token1 was collected
    event CollectFees(
        uint256 feesFromPool0,
        uint256 feesFromPool1
    );

    /// @notice Emitted when add or delete contract white list
    /// @param _address The contact address
    /// @param status true is add false is  delete
    event UpdateWhiteList(
        address indexed _address,
        bool status
    );

    /// @notice Emitted when change manager address
    /// @param _operator The manager address
    event ChangeManger(
        address indexed _operator
    );

}
