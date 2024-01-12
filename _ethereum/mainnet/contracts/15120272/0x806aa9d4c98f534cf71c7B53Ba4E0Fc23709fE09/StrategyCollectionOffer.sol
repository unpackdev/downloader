// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrderTypes.sol";
import "./IStrategy.sol";

contract StrategyCollectionOffer is IStrategy {
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
                item.tokenId == 0 &&
                item.amount == takerAsk.item.amount &&
                item.price == takerAsk.item.price),
            takerAsk.item.tokenId,
            item.amount
        );
    }

    function canExecuteTakerBid(
        OrderTypes.MakerOrder calldata,
        OrderTypes.TakerOrder calldata
    )
        external
        pure
        override
        returns (
            bool valid,
            uint256 tokenId,
            uint256 amount
        )
    {
        return (false, 0, 0);
    }
}
