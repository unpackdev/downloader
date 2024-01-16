// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./LibRichErrorsV06.sol";
import "./LibOwnableRichErrorsV06.sol";
import "./IERC20TokenV06.sol";
import "./ILiquidityProvider.sol";
import "./IERC20Bridge.sol";
import "./ILiquidityProviderSandbox.sol";


/// @dev A permissionless contract through which the ZeroXP contract can
///      safely trigger a trade on an external `ILiquidityProvider` contract.
contract LiquidityProviderSandbox is
    ILiquidityProviderSandbox
{
    using LibRichErrorsV06 for bytes;

    /// @dev Store the owner as an immutable.
    address public immutable owner;

    constructor(address owner_)
        public
    {
        owner = owner_;
    }

    /// @dev Allows only the (immutable) owner to call a function.
    modifier onlyOwner() virtual {
        if (msg.sender != owner) {
            LibOwnableRichErrorsV06.OnlyOwnerError(
                msg.sender,
                owner
            ).rrevert();
        }
        _;
    }

    /// @dev Calls `sellTokenForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    )
        external
        onlyOwner
        override
    {
        provider.sellTokenForToken(
            inputToken,
            outputToken,
            recipient,
            minBuyAmount,
            auxiliaryData
        );
    }

    /// @dev Calls `sellEthForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellEthForToken(
        ILiquidityProvider provider,
        IERC20TokenV06 outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    )
        external
        onlyOwner
        override
    {
        provider.sellEthForToken(
            outputToken,
            recipient,
            minBuyAmount,
            auxiliaryData
        );
    }

    /// @dev Calls `sellTokenForEth` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForEth(
        ILiquidityProvider provider,
        IERC20TokenV06 inputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    )
        external
        onlyOwner
        override
    {
        provider.sellTokenForEth(
            inputToken,
            payable(recipient),
            minBuyAmount,
            auxiliaryData
        );
    }
}
