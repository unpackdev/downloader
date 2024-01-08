// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IGammaRedeemerV1 {
    struct Order {
        // address of user
        address owner;
        // address of otoken to redeem
        address otoken;
        // amount of otoken to redeem
        uint256 amount;
        // vaultId of vault to settle
        uint256 vaultId;
        // true if settle vault order, else redeem otoken
        bool isSeller;
        // convert proceed to ETH, currently unused
        bool toETH;
        // fee in 1/10.000
        uint256 fee;
        // true if order is already processed
        bool finished;
    }

    event OrderCreated(
        uint256 indexed orderId,
        address indexed owner,
        address indexed otoken
    );
    event OrderFinished(uint256 indexed orderId, bool indexed cancelled);

    function createOrder(
        address _otoken,
        uint256 _amount,
        uint256 _vaultId
    ) external;

    function cancelOrder(uint256 _orderId) external;

    function shouldProcessOrder(uint256 _orderId) external view returns (bool);

    function processOrder(uint256 _orderId) external;

    function getOrdersLength() external view returns (uint256);

    function getOrders() external view returns (Order[] memory);

    function getOrder(uint256 _orderId) external view returns (Order memory);
}
