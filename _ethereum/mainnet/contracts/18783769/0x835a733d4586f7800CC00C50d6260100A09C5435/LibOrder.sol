// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LibAsset.sol";
import "./LibOrderDataV2.sol";

// https://github.com/rarible/protocol-contracts/blob/822142af31e15c8f81f59b47a57d4923141498ae/exchange-v2/contracts/LibOrder.sol
library LibOrder {
    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        //order.data is in hash for V2 orders
        if (order.dataType == LibOrderDataV2.V2) {
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt,
                        order.data
                    )
                );
        } else {
            return
                keccak256(
                    abi.encode(
                        order.maker,
                        LibAsset.hash(order.makeAsset.assetType),
                        LibAsset.hash(order.takeAsset.assetType),
                        order.salt
                    )
                );
        }
    }
}
