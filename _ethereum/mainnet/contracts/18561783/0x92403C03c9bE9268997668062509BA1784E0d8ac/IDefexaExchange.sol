pragma solidity ^0.8.0;

interface IDefexaExchange {

    error NotSupported();
    error InvalidOrder();
    error OrderTypeNotSupported(uint8 orderType);
    error TransferFailed();
    error OrderStatusInvalid(uint8 status);
    error Forbidden();
    error OrderNotFound(uint256 orderId);
    error TokensMismatch();
    error TokenNotSupported();
    error PriceMismatch(uint256 priceMaker, uint256 priceTaker);
    error OrderTypesMismatch();
    error TakerFeeTooHigh(uint256 fee);
    error FeeCollectorAddressInvalid();

    struct Order {
        uint256 id;
        uint256 createdAt;
        address user;
        address tokenA;
        address tokenB;
        uint256 amount;
        uint256 initialAmount;
        uint256 spentAmount;
        uint256 price;
        bool isBuy;
        uint8 orderType;
        uint8 status;
    }

    event NewOrder(
        address indexed user,
        uint256 orderId,
        uint256 amount,
        uint256 price,
        address baseToken,
        address quoteToken,
        uint256 ts,
        bool isBuy,
        uint8 orderType
    );

    event OrderCanceled(
        address indexed user,
        uint256 orderId,
        uint256 ts
    );

    event Withdrawal(
        address indexed user,
        uint256 orderId,
        address token,
        uint256 amount,
        uint256 ts
    );

    event OrderFilled(uint256 orderId, uint256 amountSent, uint256 amountReceived, uint256 ts);
    event OrderFilledPartially(uint256 orderId, uint256 amountSent, uint256 amountReceived, uint256 ts);

    event TakerFeeUpdated(uint256 newFee, uint256 ts);
    event FeeCollectorUpdated(address feeCollector, uint256 ts);
    event FeeGathered(address indexed user, uint256 indexed orderId, address token, uint256 amount, uint256 ts);
    event LeftoverReturned(address indexed user, uint256 indexed orderId, address token, uint256 amount, uint256 ts);

    function createOrder(
        address _baseToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _price,
        bool _isBuy,
        uint8 _orderType
    ) external payable returns (uint256);

    function createOrderWithRecipient(
        address _baseToken,
        address _quoteToken,
        uint256 _amount,
        uint256 _price,
        bool _isBuy,
        uint8 _orderType,
        address _recipient
    ) external payable returns (uint256);

    function cancelOrder(
        uint256 orderId
    ) external;

    function matchOrders(
        uint256[] memory _makers,
        uint256 _takerId
    ) external;

}
