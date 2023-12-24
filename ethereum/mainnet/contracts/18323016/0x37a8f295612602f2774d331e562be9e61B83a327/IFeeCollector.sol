// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./ERC20.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
interface IFeeCollector {
    /// @notice Swaps the contract balance.
    /// @param swapData The bytes call data to be forwarded to UniversalRouter.
    /// @param nativeValue The amount of native currency to send to UniversalRouter.
    function swapBalance(bytes calldata swapData, uint256 nativeValue) external;

    /// @notice Approves tokens for swapping and then swaps the contract balance.
    /// @param swapData The bytes call data to be forwarded to UniversalRouter.
    /// @param nativeValue The amount of native currency to send to UniversalRouter.
    /// @param tokensToApprove An array of ERC20 tokens to approve for spending.
    function swapBalance(bytes calldata swapData, uint256 nativeValue, ERC20[] calldata tokensToApprove) external;

    /// @notice Transfers the fee token balance from this contract to the fee recipient.
    /// @param feeRecipient The address to send the fee token balance to.
    /// @param amount The amount to withdraw.
    function withdrawFeeToken(address feeRecipient, uint256 amount) external;
}
