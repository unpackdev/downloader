/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Balancer V2 boosted pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./PortalBaseV2.sol";
import "./IPortalRegistry.sol";
import "./IBalancerVault.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract BalancerV2BoostedPortalOut is PortalBaseV2 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IBalancerVault public immutable VAULT;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IBalancerVault _vault
    )
        PortalBaseV2(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        VAULT = _vault;
    }

    /// @notice Remove liquidity from Balancer V2 boosted pools into network tokens/ERC20 tokens
    /// @param sellToken The Balancer V2 boosted pool address (i.e. the Phantom BPT token address)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be one of the pool tokens)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolId The ID of the pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes32 poolId
    ) external payable pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        uint256 intermediateAmount = _withdraw(
            sellToken,
            sellAmount,
            intermediateToken,
            poolId
        );

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
        );

        buyAmount = _getFeeAmount(buyAmount);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Removes the intermediate token from the pool
    /// @param sellToken The Balancer V2 boosted pool token address
    /// @param sellAmount The quantity of BPT tokens to remove from the pool
    /// @param buyToken The ERC20 token being removed (i.e. the intermediate token)
    /// @param poolId The balancer pool ID
    /// @return The quantity of buyToken acquired
    function _withdraw(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes32 poolId
    ) internal returns (uint256) {
        _approve(sellToken, address(VAULT), sellAmount);

        uint256 balance = _getBalance(address(this), buyToken);

        VAULT.swap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: sellToken,
                assetOut: buyToken,
                amount: sellAmount,
                userData: ""
            }),
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            0,
            block.timestamp
        );

        return _getBalance(address(this), buyToken) - balance;
    }
}
