// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRootChainManager.sol";
import "./IFxStateSender.sol";

/// @title Constants for use on the Ethereum network
contract EthereumConstants {
    /// @dev see https://static.matic.network/network/mainnet/v1/index.json
    /// @return polygon ERC20 predicate for transferring ERC20 tokens to polygon
    address public constant ERC20_PREDICATE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return WETH token on polygon
    address public constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return fxRoot contract which can send arbitrary state messages
    IFxStateSender public constant FX_ROOT =
        IFxStateSender(0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2);

    /// @dev see https://static.matic.network/network/mainnet/v1
    /// @return polygon main pos-bridge contract
    IRootChainManager public constant CHAIN_MANAGER =
        IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
}
