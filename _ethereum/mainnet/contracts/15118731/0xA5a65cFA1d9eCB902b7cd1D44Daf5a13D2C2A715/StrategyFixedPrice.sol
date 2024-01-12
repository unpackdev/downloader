// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrderTypes.sol";
import "./IStrategy.sol";

contract StrategyFixedPrice is IStrategy {
    // solhint-disable not-rely-on-time
    using OrderTypes for OrderTypes.MakerOrder;

    function canExecuteTakerAsk(
        OrderTypes.MakerOrder calldata makerBid,
        OrderTypes.TakerOrder calldata takerAsk
    )
        external
        view
        override
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        )
    {
        OrderTypes.OrderItem memory item = makerBid.items[takerAsk.itemIdx];
        return (
            (makerBid.startTime <= block.timestamp &&
                makerBid.endTime >= block.timestamp &&
                item.collection == takerAsk.item.collection &&
                item.tokenId == takerAsk.item.tokenId &&
                item.amount == takerAsk.item.amount &&
                item.price == takerAsk.item.price),
            item.tokenId,
            item.amount
        );
    }

    function canExecuteTakerBid(
        OrderTypes.MakerOrder calldata makerAsk,
        OrderTypes.TakerOrder calldata takerBid
    )
        external
        view
        override
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        )
    {
        OrderTypes.OrderItem memory item = makerAsk.items[takerBid.itemIdx];
        return (
            (makerAsk.startTime <= block.timestamp &&
                makerAsk.endTime >= block.timestamp &&
                item.collection == takerBid.item.collection &&
                item.tokenId == takerBid.item.tokenId &&
                item.amount == takerBid.item.amount &&
                item.price == takerBid.item.price),
            item.tokenId,
            item.amount
        );
    }
}
