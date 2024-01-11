//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ITransferManager.sol";
import "./LibOrder.sol";
import "./OrderValidator.sol";
import "./SaleKindInterface.sol";

abstract contract ExchangeCore is
    OrderValidator,
    ReentrancyGuard,
    Ownable,
    ITransferManager
{
    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    event OrderCancelled(bytes32 indexed hash, address indexed maker);
    event OrdersMatched(
        address indexed maker,
        address indexed taker,
        uint256 price
    );

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     */
    function cancelOrder(LibOrder.Order calldata order) external {
        // Checks
        require(_msgSender() == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");

        // Not canlled or finalized.
        bytes32 digest = LibOrder.hashKey(order);
        require(!cancelledOrFinalized[digest]);

        // Mark order as cancelled
        cancelledOrFinalized[digest] = true;

        // Log cancel event.
        emit OrderCancelled(digest, order.maker);
    }

    /**
     * @dev Match two orders.
     * @param sell Sell order
     * @param buy Buy order
     */
    function matchOrders(
        LibOrder.Order calldata sell,
        LibOrder.Order calldata buy
    ) external payable nonReentrant {
        /* CHECKS */

        // Require buyer to be msg.sender
        require(_msgSender() == buy.maker, "not the buyer");

        // Get hash key
        bytes32 digest = LibOrder.hashKey(sell);

        // Validate order
        validateOrder(digest, sell);

        /* Must be matchable. */
        ordersCanMatch(buy, sell);

        /* EFFECTS */

        /* Mark previously signed order(sell order) as finalized. */
        cancelledOrFinalized[digest] = true;

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        doTransfers(buy, sell);

        /* Log match event. */
        emit OrdersMatched(sell.maker, buy.maker, sell.price);
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     */
    function validateOrder(bytes32 digest, LibOrder.Order calldata order)
        internal
        view
    {
        /* Order must have not been canceled or already filled. */
        require(!cancelledOrFinalized[digest], "order canceled or finalized");

        /* Validate order. */
        OrderValidator.validate(order);
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function ordersCanMatch(
        LibOrder.Order calldata buy,
        LibOrder.Order calldata sell
    ) internal {
        /* Must be opposite-side. */
        require(buy.side == SaleKindInterface.Side.Buy, "can not match");
        require(sell.side == SaleKindInterface.Side.Sell, "can not match");

        /* Must use same payment token. */
        require(buy.paymentToken == sell.paymentToken, "can not match");

        /* Must match maker/taker addresses. */
        require(
            sell.taker == address(0) || sell.taker == buy.maker,
            "can not match"
        );
        require(
            buy.taker == address(0) || buy.taker == sell.maker,
            "can not match"
        );

        // Check send value
        if (sell.paymentToken == address(0)) {
            require(msg.value >= sell.price, "insuffient ether");
        }
    }
}
