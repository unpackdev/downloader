// SPDX-License-Identifier: MIT
// Based on ZeroEx Intl work

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./LibEIP712ExchangeDomain.sol";
import "./LibOrder.sol";
import "./LibZeroExTransaction.sol";
import "./LibEIP712.sol";
import "./LibBytes.sol";
import "./Addresses.sol";
import "./OrderValidationUtils.sol";
import "./EthBalanceChecker.sol";
import "./ExternalFunctions.sol";


// solhint-disable no-empty-blocks
contract DevUtils is
    Addresses,
    OrderValidationUtils,
    LibEIP712ExchangeDomain,
    EthBalanceChecker,
    ExternalFunctions
{
    constructor (
        address exchange_,
        address chaiBridge_,
        address dydxBridge_
    )
        public
        Addresses(
            exchange_,
            chaiBridge_,
            dydxBridge_
        )
        LibEIP712ExchangeDomain(uint256(0), address(0)) // null args because because we only use constants
    {}

    function getOrderHash(
        LibOrder.Order memory order,
        uint256 chainId,
        address exchange
    )
        public
        pure
        returns (bytes32 orderHash)
    {
        return LibOrder.getTypedDataHash(
            order,
            LibEIP712.hashEIP712Domain(_EIP712_EXCHANGE_DOMAIN_NAME, _EIP712_EXCHANGE_DOMAIN_VERSION, chainId, exchange)
        );
    }

    function getTransactionHash(
        LibZeroExTransaction.ZeroExTransaction memory transaction,
        uint256 chainId,
        address exchange
    )
        public
        pure
        returns (bytes32 transactionHash)
    {
        return LibZeroExTransaction.getTypedDataHash(
            transaction,
            LibEIP712.hashEIP712Domain(_EIP712_EXCHANGE_DOMAIN_NAME, _EIP712_EXCHANGE_DOMAIN_VERSION, chainId, exchange)
        );
    }
}
