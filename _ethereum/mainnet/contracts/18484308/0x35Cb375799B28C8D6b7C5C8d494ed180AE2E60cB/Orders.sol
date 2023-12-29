pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import "./SafeMath.sol";
import "./Math.sol";
import "./ITwapFactory.sol";
import "./ITwapPair.sol";
import "./ITwapOracle.sol";
import "./TokenShares.sol";


library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType {
        Empty,
        Deposit,
        Withdraw,
        Sell,
        Buy
    }
    enum OrderStatus {
        NonExistent,
        EnqueuedWaiting,
        EnqueuedReady,
        ExecutedSucceeded,
        ExecutedFailed,
        Canceled
    }

    event DepositEnqueued(uint256 indexed orderId, Order order);
    event WithdrawEnqueued(uint256 indexed orderId, Order order);
    event SellEnqueued(uint256 indexed orderId, Order order);
    event BuyEnqueued(uint256 indexed orderId, Order order);

    event OrderTypesDisabled(address pair, Orders.OrderType[] orderTypes, bool disabled);

    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);

    // Note on gas estimation for the full order execution in the UI:
    // Add (ORDER_BASE_COST + token transfer costs) to the actual gas usage
    // of the TwapDelay._execute* functions when updating gas cost in the UI.
    // Remember that ETH unwrap is part of those functions. It is optional,
    // but also needs to be included in the estimate.

    uint256 public constant ETHER_TRANSFER_COST = ETHER_TRANSFER_CALL_COST + 2600 + 1504; // Std cost + EIP-2929 acct access cost + Gnosis Safe receive ETH cost
    uint256 private constant BOT_ETHER_TRANSFER_COST = 10_000;
    uint256 private constant BUFFER_COST = 10_000;
    uint256 private constant ORDER_EXECUTED_EVENT_COST = 3700;
    uint256 private constant EXECUTE_PREPARATION_COST = 30_000; // dequeue + gas calculation before calls to _execute* functions

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10_000;
    uint256 public constant PAIR_TRANSFER_COST = 55_000;
    uint256 public constant REFUND_BASE_COST =
        BOT_ETHER_TRANSFER_COST + ETHER_TRANSFER_COST + BUFFER_COST + ORDER_EXECUTED_EVENT_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_BASE_COST;

    // Masks used for setting order disabled
    // Different bits represent different order types
    uint8 private constant DEPOSIT_MASK = uint8(1 << uint8(OrderType.Deposit)); //   00000010
    uint8 private constant WITHDRAW_MASK = uint8(1 << uint8(OrderType.Withdraw)); // 00000100
    uint8 private constant SELL_MASK = uint8(1 << uint8(OrderType.Sell)); //         00001000
    uint8 private constant BUY_MASK = uint8(1 << uint8(OrderType.Buy)); //           00010000

    address public constant FACTORY_ADDRESS = 0xC480b33eE5229DE3FbDFAD1D2DCD3F3BAD0C56c6; 
    uint256 public constant MAX_GAS_LIMIT = 5000000; 
    uint256 public constant GAS_PRICE_INERTIA = 20000000; 
    uint256 public constant MAX_GAS_PRICE_IMPACT = 1000000; 
    uint256 public constant DELAY = 1800; 

    address public constant NATIVE_CURRENCY_SENTINEL = address(0); // A sentinel value for the native currency to distinguish it from ERC20 tokens

    struct Data {
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => bytes32) orderQueue;
        uint256 gasPrice;
        mapping(uint256 => bool) canceled;
        // Bit on specific positions indicates whether order type is disabled (1) or enabled (0) on specific pair
        mapping(address => uint8) orderTypesDisabled;
        mapping(uint256 => bool) refundFailed;
    }

    struct Order {
        uint256 orderId;
        OrderType orderType;
        bool inverted;
        uint256 validAfterTimestamp;
        bool unwrap;
        uint256 timestamp;
        uint256 gasLimit;
        uint256 gasPrice;
        uint256 liquidity;
        uint256 value0; // Deposit: share0, Withdraw: amount0Min, Sell: shareIn, Buy: shareInMax
        uint256 value1; // Deposit: share1, Withdraw: amount1Min, Sell: amountOutMin, Buy: amountOut
        address token0; // Sell: tokenIn, Buy: tokenIn
        address token1; // Sell: tokenOut, Buy: tokenOut
        address to;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool swap;
        uint256 priceAccumulator;
        uint256 amountLimit0;
        uint256 amountLimit1;
    }

    function getOrderStatus(
        Data storage data,
        uint256 orderId,
        uint256 validAfterTimestamp
    ) internal view returns (OrderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (data.refundFailed[orderId]) {
            return OrderStatus.ExecutedFailed;
        }
        if (data.orderQueue[orderId] == bytes32(0)) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair, bool inverted) {
        pair = ITwapFactory(FACTORY_ADDRESS).getPair(tokenA, tokenB);
        require(pair != address(0), 'OS17');
        inverted = tokenA > tokenB;
    }

    function getDepositDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & DEPOSIT_MASK != 0;
    }

    function getWithdrawDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & WITHDRAW_MASK != 0;
    }

    function getSellDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & SELL_MASK != 0;
    }

    function getBuyDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & BUY_MASK != 0;
    }

    function setOrderTypesDisabled(
        Data storage data,
        address pair,
        Orders.OrderType[] calldata orderTypes,
        bool disabled
    ) external {
        uint256 orderTypesLength = orderTypes.length;
        uint8 currentSettings = data.orderTypesDisabled[pair];

        uint8 combinedMask;
        for (uint256 i; i < orderTypesLength; ++i) {
            Orders.OrderType orderType = orderTypes[i];
            require(orderType != Orders.OrderType.Empty, 'OS32');
            // zeros with 1 bit set at position specified by orderType
            // e.g. for SELL order type
            // mask for SELL    = 00001000
            // combinedMask     = 00000110 (DEPOSIT and WITHDRAW masks set in previous iterations)
            // the result of OR = 00001110 (DEPOSIT, WITHDRAW and SELL combined mask)
            combinedMask = combinedMask | uint8(1 << uint8(orderType));
        }

        // set/unset a bit accordingly to 'disabled' value
        if (disabled) {
            // OR operation to disable order
            // e.g. for disable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // mask for DEPOSIT  = 00000010
            // the result of OR  = 00010110
            currentSettings = currentSettings | combinedMask;
        } else {
            // AND operation with a mask negation to enable order
            // e.g. for enable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // 0xff              = 11111111
            // mask for Deposit  = 00000010
            // mask negation     = 11111101
            // the result of AND = 00010100
            currentSettings = currentSettings & (combinedMask ^ 0xff);
        }
        require(currentSettings != data.orderTypesDisabled[pair], 'OS01');
        data.orderTypesDisabled[pair] = currentSettings;

        emit OrderTypesDisabled(pair, orderTypes, disabled);
    }

    function markRefundFailed(Data storage data) internal {
        data.refundFailed[data.lastProcessedOrderId] = true;
    }

    /// @dev The passed in order.oderId is ignored and overwritten with the correct value, i.e. an updated data.newestOrderId.
    /// This is done to ensure atomicity of these two actions while optimizing gas usage - adding an order to the queue and incrementing
    /// data.newestOrderId (which should not be done anywhere else in the contract).
    /// Must only be called on verified orders.
    function enqueueOrder(Data storage data, Order memory order) internal {
        order.orderId = ++data.newestOrderId;
        data.orderQueue[order.orderId] = getOrderDigest(order);
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        bool swap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        {
            // scope for checks, avoids stack too deep errors
            uint256 token0TransferCost = getTransferGasCost(depositParams.token0);
            uint256 token1TransferCost = getTransferGasCost(depositParams.token1);
            checkOrderParams(
                depositParams.to,
                depositParams.gasLimit,
                depositParams.submitDeadline,
                ORDER_BASE_COST.add(token0TransferCost).add(token1TransferCost)
            );
        }
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS25');
        (address pairAddress, bool inverted) = getPair(depositParams.token0, depositParams.token1);
        require(!getDepositDisabled(data, pairAddress), 'OS46');
        {
            // scope for value, avoids stack too deep errors
            uint256 value = msg.value;

            // allocate gas refund
            if (depositParams.wrap) {
                if (depositParams.token0 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount0, 'OS1E');
                } else if (depositParams.token1 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount1, 'OS1E');
                }
            }
            allocateGasRefund(data, value, depositParams.gasLimit);
        }

        uint256 shares0 = tokenShares.amountToShares(
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.amount1 : depositParams.amount0,
            depositParams.wrap
        );
        uint256 shares1 = tokenShares.amountToShares(
            inverted ? depositParams.token0 : depositParams.token1,
            inverted ? depositParams.amount0 : depositParams.amount1,
            depositParams.wrap
        );

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Deposit,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            depositParams.wrap,
            timestamp,
            depositParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares0,
            shares1,
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.token0 : depositParams.token1,
            depositParams.to,
            depositParams.minSwapPrice,
            depositParams.maxSwapPrice,
            depositParams.swap,
            priceAccumulator,
            inverted ? depositParams.amount1 : depositParams.amount0,
            inverted ? depositParams.amount0 : depositParams.amount1
        );
        enqueueOrder(data, order);

        emit DepositEnqueued(order.orderId, order);
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, bool inverted) = getPair(withdrawParams.token0, withdrawParams.token1);
        require(!getWithdrawDisabled(data, pair), 'OS0A');
        checkOrderParams(
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS22');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);

        Order memory order = Order(
            0,
            OrderType.Withdraw,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            withdrawParams.unwrap,
            0, // timestamp
            withdrawParams.gasLimit,
            data.gasPrice,
            withdrawParams.liquidity,
            inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
            inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
            inverted ? withdrawParams.token1 : withdrawParams.token0,
            inverted ? withdrawParams.token0 : withdrawParams.token1,
            withdrawParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator
            0, // amountLimit0
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit WithdrawEnqueued(order.orderId, order);
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(sellParams.tokenIn);
        checkOrderParams(
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );

        (address pairAddress, bool inverted) = sellHelper(data, sellParams);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            sellParams.wrapUnwrap,
            timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function relayerSell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        checkOrderParams(sellParams.to, sellParams.gasLimit, sellParams.submitDeadline, ORDER_BASE_COST);

        (, bool inverted) = sellHelper(data, sellParams);

        uint256 shares = tokenShares.amountToSharesWithoutTransfer(
            sellParams.tokenIn,
            sellParams.amountIn,
            sellParams.wrapUnwrap
        );

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            false, // Never wrap/unwrap
            block.timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator - oracleV3 pairs don't need priceAccumulator
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function sellHelper(Data storage data, SellParams calldata sellParams)
        internal
        returns (address pairAddress, bool inverted)
    {
        require(sellParams.amountIn != 0, 'OS24');
        (pairAddress, inverted) = getPair(sellParams.tokenIn, sellParams.tokenOut);
        require(!getSellDisabled(data, pairAddress), 'OS13');

        // allocate gas refund
        uint256 value = msg.value;
        if (sellParams.wrapUnwrap && sellParams.tokenIn == TokenShares.WETH_ADDRESS) {
            value = msg.value.sub(sellParams.amountIn, 'OS1E');
        }
        allocateGasRefund(data, value, sellParams.gasLimit);
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(buyParams.tokenIn);
        checkOrderParams(
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(buyParams.amountOut != 0, 'OS23');
        (address pairAddress, bool inverted) = getPair(buyParams.tokenIn, buyParams.tokenOut);
        require(!getBuyDisabled(data, pairAddress), 'OS49');
        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == TokenShares.WETH_ADDRESS && buyParams.wrapUnwrap) {
            value = msg.value.sub(buyParams.amountInMax, 'OS1E');
        }

        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Buy,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            buyParams.wrapUnwrap,
            timestamp,
            buyParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            buyParams.amountOut,
            buyParams.tokenIn,
            buyParams.tokenOut,
            buyParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            buyParams.amountInMax,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit BuyEnqueued(order.orderId, order);
    }

    function checkOrderParams(
        address to,
        uint256 gasLimit,
        uint32 submitDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS04');
        require(gasLimit <= MAX_GAS_LIMIT, 'OS3E');
        require(gasLimit >= minGasLimit, 'OS3D');
        require(to != address(0), 'OS26');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS1E');
        if (value > futureFee) {
            TransferHelper.safeTransferETH(
                msg.sender,
                value.sub(futureFee),
                getTransferGasCost(NATIVE_CURRENCY_SENTINEL)
            );
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, MAX_GAS_PRICE_IMPACT);
        data.gasPrice = data.gasPrice.mul(GAS_PRICE_INERTIA.sub(scale)).add(tx.gasprice.mul(scale)).div(
            GAS_PRICE_INERTIA
        );
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity,
        bytes4 selector
    ) internal returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function dequeueOrder(Data storage data, uint256 orderId) internal {
        ++data.lastProcessedOrderId;
        require(orderId == data.lastProcessedOrderId, 'OS72');
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
    }

    function getOrderDigest(Order memory order) internal pure returns (bytes32) {
        // Used to avoid the 'stack too deep' error.
        bytes memory partialOrderData = abi.encodePacked(
            order.orderId,
            order.orderType,
            order.inverted,
            order.validAfterTimestamp,
            order.unwrap,
            order.timestamp,
            order.gasLimit,
            order.gasPrice,
            order.liquidity,
            order.value0,
            order.value1,
            order.token0,
            order.token1,
            order.to
        );

        return
            keccak256(
                abi.encodePacked(
                    partialOrderData,
                    order.minSwapPrice,
                    order.maxSwapPrice,
                    order.swap,
                    order.priceAccumulator,
                    order.amountLimit0,
                    order.amountLimit1
                )
            );
    }

    function verifyOrder(Data storage data, Order memory order) external view {
        require(getOrderDigest(order) == data.orderQueue[order.orderId], 'OS71');
    }

    
    // constant mapping for transferGasCost
    /**
     * @dev This function should either return a default value != 0 or revert.
     */
    function getTransferGasCost(address token) internal pure returns (uint256) {
        if (token == NATIVE_CURRENCY_SENTINEL) return ETHER_TRANSFER_CALL_COST;
        if (token == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 70000;
        return 60000;
    }
}
