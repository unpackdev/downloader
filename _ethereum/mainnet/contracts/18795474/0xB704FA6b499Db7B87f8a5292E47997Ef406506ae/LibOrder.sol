// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./LibAsset.sol";
/* Gambulls LibOrder 2023 */

library LibOrder {
    bytes4 constant public ORDER_SELL_TYPE = bytes4(keccak256("SELL"));
    bytes4 constant public ORDER_BUY_TYPE = bytes4(keccak256("BUY"));
    bytes4 constant public ORDER_OFFER_TYPE = bytes4(keccak256("OFFER"));
    bytes32 constant private ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,bytes4 orderType,bytes orderData,uint256 startDate,uint256 endDate,uint256 salt)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        bytes4 orderType;
        bytes orderData;
        uint256 startDate;
        uint256 endDate;
        uint256 salt;
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            LibAsset.hash(order.makeAsset),
            order.taker,
            LibAsset.hash(order.takeAsset),
            order.orderType,
            keccak256(order.orderData),
            order.startDate,
            order.endDate,
            order.salt
        ));
    }

    function validateOrderTime(Order memory order) internal view {
        require(order.startDate == 0 || order.startDate < block.timestamp, "order start validation failed");
        require(order.endDate == 0 || order.endDate > block.timestamp, "order end validation failed");
    }
}