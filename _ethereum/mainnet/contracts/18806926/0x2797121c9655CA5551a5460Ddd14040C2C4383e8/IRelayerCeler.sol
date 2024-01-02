// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @title Relayer Celer Interface
/// @author Daniel <danieldegendev@gmail.com>
interface IRelayerCeler {
    /// Deploys the fees to the desired chain
    /// @param _receiver relayer on target chain
    /// @param _target diamond address on target chain
    /// @param _chainId target chain id
    /// @param _message message to send to the message bus
    function deployFees(address _receiver, address _target, uint256 _chainId, bytes calldata _message) external payable;

    /// Pre calculates upcoming fees for deploying fees
    /// @param _target diamond address on target chain
    /// @param _message message to send to the message bus
    function deployFeesFeeCalc(address _target, bytes calldata _message) external view returns (uint256 _wei);

    /// Sends the fees to the home chain
    /// @param _asset asset that get send
    /// @param _amount amount of assets that gets send
    /// @param minMaxSlippage calculated slippage by celer
    /// @param _message message to send to the message bus
    function sendFees(address _asset, uint256 _amount, uint32 minMaxSlippage, bytes calldata _message) external payable;

    /// Pre calculates upcoming fees for sending fees
    /// @param _message message to send to the message bus
    function sendFeesFeeCalc(bytes calldata _message) external view returns (uint256 _wei);
}
