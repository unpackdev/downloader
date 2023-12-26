/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice Interface for the Base contract inherited by the Portals Router

pragma solidity 0.8.19;

interface IRouterBase {
    /// @notice Emitted when Portalling
    /// @param inputToken The ERC20 token address to spend (address(0) if network token)
    /// @param inputAmount The quantity of inputToken to send
    /// @param outputToken The ERC20 token address to buy (address(0) if network token)
    /// @param outputAmount The quantity of outputToken received
    /// @param sender The sender(signer) of the order
    /// @param broadcaster The msg.sender of the broadcasted transaction
    /// @param recipient The recipient of the outputToken
    /// @param partner The front end operator address
    event Portal(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        uint256 outputAmount,
        address indexed sender,
        address indexed broadcaster,
        address recipient,
        address indexed partner
    );

    /// Thrown when insufficient liquidity is received after deposit or withdrawal
    /// @param outputAmount The amount of liquidity received
    /// @param minOutputAmount The minimum acceptable quantity of liquidity received
    error InsufficientBuy(
        uint256 outputAmount, uint256 minOutputAmount
    );
}
