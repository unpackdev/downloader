// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./DataTypes.sol";

/// @title NF3 OTC Broking Protocol Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to broking features of the platform.

interface IBrokers {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum BrokersErrorCodes {
        CALLER_IS_NOT_BROKER,
        ZERO_ADDRESS,
        TIME_HAS_EXPIRED,
        INVALID_KITTY,
        INVALID_PUNK,
        INVALID_NONCE,
        INVALID_ASSET_TYPE,
        INSUFFICIENT_TOKEN_AMOUNT_FOR_FEE_DEDUCTION,
        FEE_TOKEN_MISSING_FROM_CONTRA
    }

    error BrokersError(BrokersErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when swap has done.
    /// @param tradeInfo Details of the trade setup by broker
    /// @param broker Broker address
    event BrokerSwapped(TradeInfo tradeInfo, address indexed broker);

    /// @dev Emits when first user's assets go to second user's asset as well as the fee.
    /// @param assets Asset that got transferred
    /// @param from Transferred assets from this user
    /// @param to Transferred assets to this user
    event AssetsTransferred(Assets assets, address from, address to);

    /// @dev Emits when fee has transferred to the broker and NF3 platform.
    /// @param from User from which fees got transferred
    /// @param fees Fee details that got transferred
    event FeeTransferred(address from, Fees fees);

    /// @dev Emits when new broker has registered.
    /// @param broker Broker address
    event BrokerRegistered(address indexed broker);

    /// @dev Emits when status has changed.
    /// @param owner User whose nonce is updated
    /// @param nonce Value of updated nonce
    event NonceSet(address owner, uint256 nonce);

    /// -----------------------------------------------------------------------
    /// Broker Action
    /// -----------------------------------------------------------------------

    /// @dev Broker swap funtion.
    /// @dev This function is called by only broker.
    /// @param tradeInfo Details of the trade setup by broker
    /// @param makerSignature Trade maker's signature
    /// @param makerContra Maker's contra option
    /// @param takerSignature Trade taker's signature
    /// @param takerContra Taker's contra option
    function swap(
        TradeInfo calldata tradeInfo,
        bytes memory makerSignature,
        bool makerContra,
        bytes memory takerSignature,
        bool takerContra
    ) external;
}
