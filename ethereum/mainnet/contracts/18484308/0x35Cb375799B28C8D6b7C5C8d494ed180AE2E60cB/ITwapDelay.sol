pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import "./Orders.sol";

interface ITwapDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event FactoryGovernorSet(address factoryGovernor);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event RelayerSet(address relayer);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event ToleranceSet(address pair, uint16 amount);
    event NonRebasingTokenSet(address token, bool isNonRebasing);

    function factory() external view returns (address);

    function factoryGovernor() external view returns (address);

    function relayer() external view returns (address);

    function owner() external view returns (address);

    function isBot(address bot) external view returns (bool);

    function getTolerance(address pair) external view returns (uint16);

    function isNonRebasingToken(address token) external view returns (bool);

    function gasPriceInertia() external view returns (uint256);

    function gasPrice() external view returns (uint256);

    function maxGasPriceImpact() external view returns (uint256);

    function maxGasLimit() external view returns (uint256);

    function delay() external view returns (uint256);

    function totalShares(address token) external view returns (uint256);

    function weth() external view returns (address);

    function getTransferGasCost(address token) external pure returns (uint256);

    function getDepositDisabled(address pair) external view returns (bool);

    function getWithdrawDisabled(address pair) external view returns (bool);

    function getBuyDisabled(address pair) external view returns (bool);

    function getSellDisabled(address pair) external view returns (bool);

    function getOrderStatus(uint256 orderId, uint256 validAfterTimestamp) external view returns (Orders.OrderStatus);

    function setOrderTypesDisabled(
        address pair,
        Orders.OrderType[] calldata orderTypes,
        bool disabled
    ) external;

    function setOwner(address _owner) external;

    function setFactoryGovernor(address _factoryGovernor) external;

    function setBot(address _bot, bool _isBot) external;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function relayerSell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(Orders.Order[] calldata orders) external payable;

    function retryRefund(Orders.Order calldata order) external;

    function cancelOrder(Orders.Order calldata order) external;

    function syncPair(address token0, address token1) external returns (address pairAddress);
}
