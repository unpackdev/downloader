// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOrderBookEvents {
    enum Quality {
        Poor,
        Fair,
        Good,
        Excellent,
        LikeNew,
        New
    }
    enum Method {
        Fiat,
        Crypto
    }
    enum Status {
        Idle,
        Open,
        Pending,
        Fulfilled,
        Cancelled,
        Dispute
    }
    enum CancelReason {
        Delist,
        Dispute
    }

    struct Order {
        address from; // Order creator who listed the NFT
        address to;
        address drop;
        uint256 tokenId;
        Quality quality;
        uint256 price; // price in Native currency
        Method method; // Fiat vs Crypto ??? to be considered
        Status status; // Current status of Order
        uint256 expiry; // UNIX timestamp - UTC time
    }

    // Might include drop or collection info
    event OrderCreated(
        uint256 orderId,
        address from,
        address drop,
        uint256 tokenId,
        uint256 price
    );
    event OrderPurchased(uint256 orderId, Status status);
    event OrderFullfilled(uint256 orderId);
    event OrderCancelled(uint256 orderId, CancelReason reason);
}

interface IOrderBook is IOrderBookEvents {
    function list(
        address drop,
        uint256 tokenId,
        uint256 price,
        Quality quality,
        uint256 expiry
    ) external;

    function delist(uint256 orderId) external;

    function buy(uint256 tokenId) external payable;

    function fulfill(uint256 orderId) external;

    function dispute(uint256 orderId) external;

    function getOrder(uint256 orderId) external view returns (Order memory);

    function getOpenOrders() external view returns (Order[] memory);

    function orderCount() external view returns (uint256);

    // function getOrdersByUser(address user) external view returns (Order[] memory);
}
