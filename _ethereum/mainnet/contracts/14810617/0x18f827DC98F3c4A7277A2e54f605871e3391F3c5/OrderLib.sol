// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetLib.sol";
import "./OrderExtLib.sol";

library OrderLib {
    bytes4 public constant CREATE_ORDER_TYPE = bytes4(keccak256("CREATE"));
    bytes4 public constant UPDATE_ORDER_TYPE = bytes4(keccak256("UPDATE"));
    bytes4 public constant CANCEL_ORDER_TYPE = bytes4(keccak256("CANCEL"));
    bytes4 public constant FINALIZE_ORDER_TYPE = bytes4(keccak256("FINALIZE"));

    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "OrderData(address maker,AssetData makeAsset,address taker,AssetData takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 orderType,bytes data)AssetData(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    struct OrderData {
        address maker;
        AssetLib.AssetData makeAsset;
        address taker;
        AssetLib.AssetData takeAsset;
        uint256 salt;
        uint256 start;
        uint256 end;
        bytes4 orderType;
        bytes data;
    }

    function hashKey(OrderData memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.maker,
                    order.taker,
                    order.salt,
                    order.start,
                    order.end,
                    order.data
                )
            );
    }

    function hash(OrderData memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    AssetLib.hash(order.makeAsset),
                    order.taker,
                    AssetLib.hash(order.takeAsset),
                    order.salt,
                    order.start,
                    order.end,
                    order.orderType,
                    keccak256(order.data)
                )
            );
    }

    function validate(OrderData memory order)
        internal
        pure
        returns (bool, string memory)
    {
        if (order.maker == address(0)) {
            return (false, "OrderLib: maker validation failed");
        } else if (
            order.makeAsset.value == 0 ||
            order.makeAsset.assetType.assetClass == bytes4(0)
        ) {
            return (false, "OrderLib: makeAsset validation failed");
        } else if (order.taker == address(0)) {
            return (false, "OrderLib: taker validation failed");
        } else if (
            order.takeAsset.value == 0 ||
            order.takeAsset.assetType.assetClass == bytes4(0)
        ) {
            return (false, "OrderLib: takeAsset validation failed");
        } else if (order.salt == 0) {
            return (false, "OrderLib: salt validation failed");
        } else if (order.start == 0) {
            return (false, "OrderLib: start validation failed");
        } else if (order.end == 0) {
            return (false, "OrderLib: end validation failed");
        } else if (
            !(order.orderType == CREATE_ORDER_TYPE ||
                order.orderType == UPDATE_ORDER_TYPE ||
                order.orderType == CANCEL_ORDER_TYPE ||
                order.orderType == FINALIZE_ORDER_TYPE)
        ) {
            return (false, "OrderLib: orderType validation failed");
        }
        return OrderExtLib.validate(OrderExtLib.decodeOrderExtData(order.data));
    }
}
