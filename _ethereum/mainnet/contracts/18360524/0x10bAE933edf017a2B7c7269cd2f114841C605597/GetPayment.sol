// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

abstract contract IERC20Extented is IERC20 {
    function decimals() public view virtual returns (uint8);
}

/**
 * @title GetPayment Contract
 * @notice This contract receives payment for orders
 */

contract GetPayment is AccessControl {
    // error constants
    string constant DEFAULT_ADMIN_ERROR = "need DEFAULT_ADMIN_ROLE";
    string constant TOKEN_ADMIN_ERROR = "need TOKEN_ADMIN_ROLE";
    string constant ORDER_ADMIN_ERROR = "need ORDER_ADMIN_ROLE";
    string constant ORACLE_ADRESS_ERROR = "INVALID_ORACLE_ADDRESS";
    string constant TOKEN_ADRESS_ERROR = "INVALID_TOKEN_ADDRESS";
    string constant TOKEN_ADDED_ERROR = "TOKEN_ALREADY_ADDED";
    string constant TOKEN_NOT_ADDED_ERROR = "TOKEN_NOT_ADDED";
    string constant BAD_TOKEN_ERROR = "BAD_TOKEN_FOR_PRICE_CALCULATIONS";
    string constant ZERO_DECIMALS_ERROR = "INVALID_DECIMALS";
    string constant TIME_ERROR = "BAD_EXPIRATION_TIME";
    string constant AMOUNT_ERROR = "INVALID_AMOUNT";
    string constant BALANCE_ERROR = "BALANCE_IS_NOT_ENOUGH";
    string constant SEND_ERROR = "FAILED_TO_SEND";
    string constant NOT_OWNER_ERROR = "msg.sender_NOT_OWNER";
    string constant ORDER_EXISTS_ERROR = "ORDER_ALREADY_EXIST";
    string constant ORDER_FULFILL_ERROR = "ORDER_FULFILLED";
    string constant ORDER_NOT_EXISTS_ERROR = "ORDER_NOT_EXIST";
    string constant ORDER_EXPIRED_ERROR = "ORDER_EXPIRED";
    string constant NATIVE_TOKEN_ERROR = "NATIVE_NOT_VALID_METHOD";
    string constant NATIVE_ADDRESS_ERROR = "NATIVE_ORACLE_ADDRESS_NOT_SET";
    string constant NATIVE_DECIMALS_ERROR = "NATIVE_DECIMALS_NOT_SET";
    string constant PAYMENT_NATIVE_ERROR = "PAYMENT_IS_NATIVE";
    string constant PAYMENT_NOT_NATIVE_ERROR = "PAYMENT_IS_NOT_NATIVE";

    address public nativePriceOracleAddress;
    uint256 nativeTokenDecimals;
    // when native payment method available, user can place an order that pays for native tokens
    bool public isNativeTokenValidPaymentMethod;
    // mapping of ERC20 tokens available for payment
    mapping(address => address) public paymentTokenPriceOracleAddress;
    // order expiration time
    uint256 public expirationTimeSeconds;

    enum OrderStatus {
        NOT_EXISTS,
        EXISTS,
        FULFILLED
    }
    struct Order {
        address owner;
        uint256 amountUSD;
        address paymentToken;
        uint256 amountToken;
        uint256 initializedAt;
        uint256 expiresAt;
        bool isPaymentNative;
        OrderStatus status;
    }
    mapping(bytes32 => Order) orders;

    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant ORDER_ADMIN_ROLE = keccak256("ORDER_ADMIN_ROLE");

    event OrderFulfilledERC20(
        address indexed purchaser,
        bytes32 indexed orderId,
        uint256 indexed timestamp,
        uint256 amountUSD,
        address paymentTokenAddress,
        uint256 amountToken
    );

    event OrderFulfilledNative(
        address indexed purchaser,
        bytes32 indexed orderId,
        uint256 indexed timestamp,
        uint256 amountUSD,
        uint256 amountNative
    );

    /**
     * @dev common parameters are given through constructor.
     * @param _expirationTimeSeconds order expiration time in seconds
     **/
    constructor(uint256 _expirationTimeSeconds) {
        require(_expirationTimeSeconds > 0, TIME_ERROR);
        expirationTimeSeconds = _expirationTimeSeconds;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(TOKEN_ADMIN_ROLE, _msgSender());
        _setupRole(ORDER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev calculate the price in ERC20 token for a given amount of usd
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     * @param tokenAddress address of ERC20 token
     */
    function calculatePriceERC20(uint256 amountUSD, address tokenAddress) public view returns (uint256) {
        address oracleAddress = paymentTokenPriceOracleAddress[tokenAddress];
        require(oracleAddress != address(0), BAD_TOKEN_ERROR);
        (, int answer, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        uint8 usdDecimals = AggregatorV3Interface(oracleAddress).decimals();
        uint8 tokenDecimals = IERC20Extented(tokenAddress).decimals();
        uint256 price = (amountUSD * (10 ** usdDecimals) * (10 ** tokenDecimals)) / uint256(answer);
        return price;
    }

    /**
     * @dev calculate the price in native token for a given amount of usd
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function calculatePriceNative(uint256 amountUSD) public view returns (uint256) {
        address oracleAddress = nativePriceOracleAddress;
        require(oracleAddress != address(0), BAD_TOKEN_ERROR);
        require(nativeTokenDecimals != 0, ZERO_DECIMALS_ERROR);
        (, int answer, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        uint8 usdDecimals = AggregatorV3Interface(oracleAddress).decimals();
        uint256 price = (amountUSD * (10 ** usdDecimals) * (10 ** nativeTokenDecimals)) / uint256(answer);
        return price;
    }

    /**
     * @dev set Chainlink price oracle address. Called only by TOKEN_ADMIN
     * @param oracleAddress  Chainlink price oracle address of NativeToken/USD pair
     */
    function setNativePriceOracleAddress(address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        nativePriceOracleAddress = oracleAddress;
    }

    /**
     * @dev set decimals of native token. Called only by TOKEN_ADMIN
     * @param nativeDecimals decimals of native token
     */

    function setNativeTokenDecimals(uint8 nativeDecimals) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(nativeDecimals != 0, ZERO_DECIMALS_ERROR);
        nativeTokenDecimals = nativeDecimals;
    }

    /**
     * @dev set order expiration time. Called only by DEFAULT_ADMIN
     * @param _expirationTimeSeconds order expiration time in seconds
     */

    function setExpirationTimeSeconds(uint256 _expirationTimeSeconds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(_expirationTimeSeconds > 0, TIME_ERROR);
        expirationTimeSeconds = _expirationTimeSeconds;
    }

    /**
     * @dev enable or disable the ability to pay for an order using native tokens. Called only by DEFAULT_ADMIN
     * @param isNativeValid boolean whether payment for the order with a native token is available
     */

    function setIsNativeTokenValidPaymentMethod(bool isNativeValid) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        isNativeTokenValidPaymentMethod = isNativeValid;
    }

    /**
     * @dev add a new payment ERC20 token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param oracleAddress Chainlink price oracle address of Token/USD pair
     */

    function addPaymentToken(address tokenAddress, address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        require(paymentTokenPriceOracleAddress[tokenAddress] == address(0), TOKEN_ADDED_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = oracleAddress;
    }

    /**
     * @dev change the oracle address of the payment token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param oracleAddress Chainlink price oracle address of Token/USD pair
     */

    function setPaymentTokenOracleAddress(address tokenAddress, address oracleAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        require(oracleAddress != address(0), ORACLE_ADRESS_ERROR);
        require(paymentTokenPriceOracleAddress[tokenAddress] != address(0), TOKEN_NOT_ADDED_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = oracleAddress;
    }

    /**
     * @dev remove payment token. Called only by TOKEN_ADMIN
     * @param tokenAddress address of ERC20 token
     */

    function removePaymentToken(address tokenAddress) external {
        require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), TOKEN_ADMIN_ERROR);
        require(tokenAddress != address(0), TOKEN_ADRESS_ERROR);
        paymentTokenPriceOracleAddress[tokenAddress] = address(0);
    }

    /**
     * @dev withdraw ERC20 token from the contract address to msgSender address. Called only by DEFAULT_ADMIN
     * @param tokenAddress address of ERC20 token
     * @param amount amount of tokens to withdraw
     */

    function withdrawERC20Tokens(address tokenAddress, uint256 amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(amount != 0, AMOUNT_ERROR);
        uint256 balance = IERC20Extented(tokenAddress).balanceOf(address(this));
        require(balance >= amount, BALANCE_ERROR);
        IERC20Extented(tokenAddress).transfer(_msgSender(), amount);
    }

    /**
     * @dev withdraw native token from the contract address to msgSender address. Called only by DEFAULT_ADMIN
     * @param amount amount of tokens to withdraw
     */

    function withdrawNative(uint256 amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), DEFAULT_ADMIN_ERROR);
        require(amount != 0, AMOUNT_ERROR);
        uint256 balance = address(this).balance;
        require(balance >= amount, BALANCE_ERROR);
        (bool sent, ) = payable(_msgSender()).call{value: amount}("");
        require(sent, SEND_ERROR);
    }

    /**
     * @dev place an order that pays for ERC20 tokens
     * @param orderId id of order
     * @param paymentToken the token that will be used to pay for the order
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function placeOrderERC20(bytes32 orderId, address paymentToken, uint256 amountUSD) external {
        require(!(isOrderPresented(orderId)), ORDER_EXISTS_ERROR);
        require(paymentTokenPriceOracleAddress[paymentToken] != address(0), TOKEN_ADRESS_ERROR);
        require(amountUSD > 0, AMOUNT_ERROR);
        uint256 timestamp = _now();
        orders[orderId] = Order(
            _msgSender(),
            amountUSD,
            paymentToken,
            calculatePriceERC20(amountUSD, paymentToken),
            timestamp,
            timestamp + expirationTimeSeconds,
            false,
            OrderStatus.EXISTS
        );
    }

    /**
     * @dev place an order that pays for native tokens
     * @param orderId id of order
     * @param amountUSD price in usd. amountUSD  must be an integer, 1 amountUSD = 1 USD
     */
    function placeOrderNative(bytes32 orderId, uint256 amountUSD) external {
        require(isNativeTokenValidPaymentMethod, NATIVE_TOKEN_ERROR);
        require(!(isOrderPresented(orderId)), ORDER_EXISTS_ERROR);
        require(nativePriceOracleAddress != address(0), NATIVE_ADDRESS_ERROR);
        require(nativeTokenDecimals != 0, NATIVE_DECIMALS_ERROR);
        require(amountUSD > 0, AMOUNT_ERROR);
        uint256 timestamp = _now();
        orders[orderId] = Order(
            _msgSender(),
            amountUSD,
            address(0),
            calculatePriceNative(amountUSD),
            timestamp,
            timestamp + expirationTimeSeconds,
            true,
            OrderStatus.EXISTS
        );
    }

    /**
     * @dev performs the execution of an order that is paid for by a ERC20 token
     * @param orderId id of order
     */

    function fulfillOrderERC20(bytes32 orderId) external {
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (
            address owner,
            uint256 amountUSD,
            address paymentToken,
            uint256 amountToken,
            ,
            uint256 expiresAt,
            bool isPaymentNative,
            OrderStatus status
        ) = getOrder(orderId);
        require(owner == _msgSender(), NOT_OWNER_ERROR);
        uint256 timestamp = _now();
        require(timestamp < expiresAt, ORDER_EXPIRED_ERROR);
        require(status == OrderStatus.EXISTS, ORDER_FULFILL_ERROR);
        require(!isPaymentNative, PAYMENT_NATIVE_ERROR);

        orders[orderId].status = OrderStatus.FULFILLED;

        IERC20Extented(paymentToken).transferFrom(owner, address(this), amountToken);
        emit OrderFulfilledERC20(owner, orderId, timestamp, amountUSD, paymentToken, amountToken);
    }

    /**
     * @dev performs the execution of an order that is paid for by a native token
     * @param orderId id of order
     */

    function fulfillOrderNative(bytes32 orderId) external payable {
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (address owner, uint256 amountUSD, , uint256 amountToken, , uint256 expiresAt, bool isPaymentNative, OrderStatus status) = getOrder(
            orderId
        );
        require(msg.value == amountToken, AMOUNT_ERROR);
        require(owner == _msgSender(), NOT_OWNER_ERROR);
        uint256 timestamp = _now();
        require(timestamp < expiresAt, ORDER_EXPIRED_ERROR);
        require(status == OrderStatus.EXISTS, ORDER_FULFILL_ERROR);
        require(isPaymentNative, PAYMENT_NOT_NATIVE_ERROR);

        orders[orderId].status = OrderStatus.FULFILLED;

        emit OrderFulfilledNative(owner, orderId, timestamp, amountUSD, amountToken);
    }

    /**
     * @dev gets a boolean value that is true if the order exists or has been fulfilled
     * @param orderId id of order
     */

    function isOrderPresented(bytes32 orderId) public view returns (bool) {
        return (orders[orderId].status == OrderStatus.EXISTS || orders[orderId].status == OrderStatus.FULFILLED);
    }

    /**
     * @dev gets a boolean value whether this token is available for order payment
     * @param paymentToken address of ERC20 token
     */

    function paymentTokenAvailable(address paymentToken) public view returns (bool) {
        return paymentTokenPriceOracleAddress[paymentToken] != address(0);
    }

    /**
     * @dev cancel not fulfilled order. Called only by ORDER_ADMIN
     * @param orderId id of order
     */

    function cancelOrder(bytes32 orderId) external {
        require(hasRole(ORDER_ADMIN_ROLE, _msgSender()), ORDER_ADMIN_ERROR);
        require(isOrderPresented(orderId), ORDER_NOT_EXISTS_ERROR);
        (, , , , , , , OrderStatus status) = getOrder(orderId);
        require(status != OrderStatus.FULFILLED, ORDER_FULFILL_ERROR);

        orders[orderId] = Order(address(0), 0, address(0), 0, 0, 0, false, OrderStatus.NOT_EXISTS);
    }

    /**
     * @dev get parameters of order
     * @param orderId id of order
     * @return owner the user who placed the order
     * @return amountUSD order price in usd
     * @return paymentToken the token that will be used to pay for the order
     * @return amountToken order price in payment token, this amount will be debited upon fulfill of the order
     * @return initializedAt the time the order was placed
     * @return expiresAt the time the order will expire
     * @return isPaymentNative payment will be in native tokens
     * @return status status of order
     */
    function getOrder(
        bytes32 orderId
    )
        public
        view
        returns (
            address owner,
            uint256 amountUSD,
            address paymentToken,
            uint256 amountToken,
            uint256 initializedAt,
            uint256 expiresAt,
            bool isPaymentNative,
            OrderStatus status
        )
    {
        Order memory _order = orders[orderId];
        owner = _order.owner;
        amountUSD = _order.amountUSD;
        paymentToken = _order.paymentToken;
        amountToken = _order.amountToken;
        initializedAt = _order.initializedAt;
        expiresAt = _order.expiresAt;
        isPaymentNative = _order.isPaymentNative;
        status = _order.status;
    }

    // Returns block.timestamp, overridable for test purposes.
    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
