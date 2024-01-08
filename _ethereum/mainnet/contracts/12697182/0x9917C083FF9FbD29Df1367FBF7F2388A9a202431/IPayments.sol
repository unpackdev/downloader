// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPayments {
    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    /// @param amountMinimum The minimum amount of WETH to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Tips miners using the WETH balance in the contract and then transfers the remainder to recipient
    /// @dev The recipientMinimum parameter prevents malicious contracts from stealing the ETH from users
    /// @param tipAmount Tip amount
    /// @param amountMinimum The minimum amount of WETH to withdraw
    /// @param recipient The destination address of the ETH left after tipping
    function unwrapWETHAndTip(
        uint256 tipAmount, 
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Tips miners using the ETH balance in the contract + msg.value
    /// @param tipAmount Tip amount
    function tip(
        uint256 tipAmount
    ) external payable;
}
