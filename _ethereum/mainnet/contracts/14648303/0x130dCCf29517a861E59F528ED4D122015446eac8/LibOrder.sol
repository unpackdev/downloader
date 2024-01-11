//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SaleKindInterface.sol";

library LibOrder {
    struct Order {
        /* Order maker address. */
        address payable maker;
        /* Order taker address, if specified. */
        address payable taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint256 makerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerFee;
        /* Order fee recipient or zero address for taker order. */
        address payable feeRecipient;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Price of the order (in paymentTokens). */
        uint256 price;
        /* Order salt, used to prevent duplicate signatures. */
        uint256 salt;
        /* Order signature.*/
        bytes signature;
        /* Calldata. */
        bytes data;
    }

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address maker,address taker,uint256 makerFee,uint256 takerFee,address feeRecipient,uint8 side,address paymentToken,uint256 price,uint256 salt)"
        );

    function hashKey(Order calldata order) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(order.maker, order.paymentToken, order.salt));
    }

    function hash(LibOrder.Order calldata order)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.taker,
                    order.makerFee,
                    order.takerFee,
                    order.feeRecipient,
                    order.side,
                    order.paymentToken,
                    order.price,
                    order.salt
                )
            );
    }
}
