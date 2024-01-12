// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OrderTypes.sol";
import "./IStrategy.sol";

contract StrategyPrivateSale is IStrategy {
    // solhint-disable not-rely-on-time
    using OrderTypes for OrderTypes.MakerOrder;

    function canExecuteTakerAsk(
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
        address buyer = abi.decode(makerAsk.params, (address));
        return (
            (buyer == takerBid.taker &&
                makerAsk.startTime <= block.timestamp &&
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
