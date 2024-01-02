// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Types.sol";

/**
 * @title ItemTypes
 * @notice This library contains item type
 */
library ItemTypes {
    // keccak256("Item(bytes32 metadata,address currency,uint256 price)")
    bytes32 internal constant ITEM_HASH = 0x99538f890dbf53a4e5329481864f72e3dde339b405b9dd1a0a5d467ab0005a55;

    // keccak256("ItemOrder(uint256 nonce,bytes32 metadata,address currency,uint256 price,uint256 deadline,address referrer)")
    bytes32 internal constant ITEM_ORDER_HASH = 0x05dfeec21f3d754d24a645c29e00f4c8a2f08f68c04fad114a57df843d960fa8;

    struct ItemOrder {
        uint256 nonce; // order nonce (must be unique)
        bytes32 metadata;
        address currency; // currency (e.g., ETH -> address(0))
        uint256 price; // price (token amount )
        uint256 deadline; // deadline in timestamp
        address referrer;
        Types.Signature operatorSignature;
        Types.Signature systemSignature;
    }

    function operatorHash(ItemOrder calldata itemOrder) internal pure returns (bytes32) {
        return keccak256(abi.encode(ITEM_HASH, itemOrder.metadata, itemOrder.currency, itemOrder.price));
    }

    function hash(ItemOrder calldata itemOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ITEM_ORDER_HASH,
                    itemOrder.nonce,
                    itemOrder.metadata,
                    itemOrder.currency,
                    itemOrder.price,
                    itemOrder.deadline,
                    itemOrder.referrer
                )
            );
    }
}
