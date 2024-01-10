// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ITwapPair.sol";
import "./ITwapDelay.sol";
import "./IWETH.sol";
import "./SafeMath.sol";
import "./Orders.sol";
import "./TokenShares.sol";
import "./AddLiquidity.sol";
import "./WithdrawHelper.sol";

contract TwapDelay is ITwapDelay {
    using SafeMath for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;
    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    uint256 private constant ORDER_CANCEL_TIME = 24 hours;
    uint256 private constant BOT_EXECUTION_TIME = 20 minutes;
    uint256 private constant ORDER_LIFESPAN = 48 hours;

    address public override owner;
    mapping(address => bool) public override isBot;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
        tokenShares.setWeth(_weth);
        orders.delay = 30 minutes;
        orders.maxGasLimit = 5_000_000;
        orders.gasPriceInertia = 20_000_000;
        orders.maxGasPriceImpact = 1_000_000;
        orders.setTransferGasCost(address(0), Orders.ETHER_TRANSFER_CALL_COST);

        emit OwnerSet(msg.sender);
    }

    function getTransferGasCost(address token) external view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositOrder(uint256 orderId) external view override returns (Orders.DepositOrder memory order) {
        return orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) external view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) external view override returns (Orders.SellOrder memory order) {
        return orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) external view override returns (Orders.BuyOrder memory order) {
        return orders.getBuyOrder(orderId);
    }

    function getDepositDisabled(address pair) external view override returns (bool) {
        return orders.getDepositDisabled(pair);
    }

    function getWithdrawDisabled(address pair) external view override returns (bool) {
        return orders.getWithdrawDisabled(pair);
    }

    function getBuyDisabled(address pair) external view override returns (bool) {
        return orders.getBuyDisabled(pair);
    }

    function getSellDisabled(address pair) external view override returns (bool) {
        return orders.getSellDisabled(pair);
    }

    function getOrderStatus(uint256 orderId) external view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'TD06');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function factory() external view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) external view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function weth() external view override returns (address) {
        return tokenShares.weth;
    }

    function delay() external view override returns (uint32) {
        return orders.delay;
    }

    function lastProcessedOrderId() external view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() external view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) external view returns (Orders.OrderType orderType, uint32 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function isOrderCanceled(uint256 orderId) external view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() external view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() external view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() external view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() external view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external override {
        require(msg.sender == owner, 'TD00');
        orders.setOrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TD00');
        require(_owner != owner, 'TD01');
        require(_owner != address(0), 'TD02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setBot(address _bot, bool _isBot) external override {
        require(msg.sender == owner, 'TD00');
        require(_isBot != isBot[_bot], 'TD01');
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) external override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint32 _delay) external override {
        require(msg.sender == owner, 'TD00');
        require(_delay != orders.delay, 'TD01');
        orders.delay = _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) external override {
        require(msg.sender == owner, 'TD00');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external override {
        require(msg.sender == owner, 'TD00');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) external override {
        require(msg.sender == owner, 'TD00');
        orders.setTransferGasCost(token, gasCost);
    }

    function deposit(Orders.DepositParams calldata depositParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.deposit(depositParams, tokenShares);
        return orders.newestOrderId;
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.withdraw(withdrawParams);
        return orders.newestOrderId;
    }

    function sell(Orders.SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        orders.sell(sellParams, tokenShares);
        return orders.newestOrderId;
    }

    function buy(Orders.BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        orders.buy(buyParams, tokenShares);
        return orders.newestOrderId;
    }

    function execute(uint256 n) external override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted = false;
        bool senderCanExecute = isBot[msg.sender] || isBot[address(0)];
        for (uint256 i = 0; i < n; i++) {
            if (orders.canceled[orders.lastProcessedOrderId + 1]) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(senderCanExecute || block.timestamp >= validAfterTimestamp + BOT_EXECUTION_TIME, 'TD00');
            orderExecuted = true;
            if (orderType == Orders.OrderType.Deposit) {
                executeDeposit();
            } else if (orderType == Orders.OrderType.Withdraw) {
                executeWithdraw();
            } else if (orderType == Orders.OrderType.Sell) {
                executeSell();
            } else if (orderType == Orders.OrderType.Buy) {
                executeBuy();
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    function executeDeposit() internal {
        uint256 gasStart = gasleft();
        Orders.DepositOrder memory depositOrder = orders.dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                depositOrder.to,
                token0,
                depositOrder.share0,
                token1,
                depositOrder.share1,
                depositOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            depositOrder.gasLimit,
            depositOrder.gasPrice,
            gasStart,
            depositOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeWithdraw() internal {
        uint256 gasStart = gasleft();
        Orders.WithdrawOrder memory withdrawOrder = orders.dequeueWithdrawOrder();
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            refundSuccess = refundLiquidity(pair, withdrawOrder.to, withdrawOrder.liquidity);
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(
            withdrawOrder.gasLimit,
            withdrawOrder.gasPrice,
            gasStart,
            withdrawOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeSell() internal {
        uint256 gasStart = gasleft();
        Orders.SellOrder memory sellOrder = orders.dequeueSellOrder();
        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        Orders.BuyOrder memory buyOrder = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        finalizeOrder(refundSuccess);
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function finalizeOrder(bool refundSuccess) private {
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_BASE_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'TD40');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = TransferHelper.transferETH(to, value, orders.transferGasCosts[address(0)]);
        emit EthRefund(to, success, value);
    }

    function refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) private returns (bool) {
        if (share == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: orders.transferGasCosts[token] }(
            abi.encodeWithSelector(this._refundToken.selector, token, to, share, unwrap)
        );
        if (!success) {
            emit RefundFailed(to, token, share, data);
        }
        return success;
    }

    function refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) private returns (bool) {
        (bool success, bytes memory data) = address(this).call{
            gas: orders.transferGasCosts[token0].add(orders.transferGasCosts[token1])
        }(abi.encodeWithSelector(this._refundTokens.selector, to, token0, share0, token1, share1, unwrap));
        if (!success) {
            emit RefundFailed(to, token0, share0, data);
            emit RefundFailed(to, token1, share1, data);
        }
        return success;
    }

    function _refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) external {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public {
        require(msg.sender == address(this), 'TD00');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share);
            IWETH(tokenShares.weth).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount, orders.transferGasCosts[address(0)]);
        } else {
            TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share));
        }
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) private returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: Orders.PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(this._refundLiquidity.selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) external {
        require(msg.sender == address(this), 'TD00');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(Orders.DepositOrder memory depositOrder) external {
        require(msg.sender == address(this), 'TD00');
        require(depositOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pair, address token0, address token1, uint256 amount0Left, uint256 amount1Left) = _initialDeposit(
            depositOrder
        );
        if (depositOrder.swap) {
            if (amount0Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit0(
                    pair,
                    token0,
                    amount0Left,
                    depositOrder.minSwapPrice,
                    encodePriceInfo(pair, depositOrder.priceAccumulator, depositOrder.timestamp)
                );
            } else if (amount1Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit1(
                    pair,
                    token1,
                    amount1Left,
                    depositOrder.maxSwapPrice,
                    encodePriceInfo(pair, depositOrder.priceAccumulator, depositOrder.timestamp)
                );
            }
        }
        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left) = AddLiquidity.addLiquidityAndMint(
                pair,
                depositOrder.to,
                token0,
                token1,
                amount0Left,
                amount1Left
            );
        }

        _refundDeposit(depositOrder.to, token0, token1, amount0Left, amount1Left);
    }

    function _initialDeposit(Orders.DepositOrder memory depositOrder)
        private
        returns (
            address pair,
            address token0,
            address token1,
            uint256 amount0Left,
            uint256 amount1Left
        )
    {
        (pair, token0, token1) = orders.getPairInfo(depositOrder.pairId);
        uint256 amount0Desired = tokenShares.sharesToAmount(token0, depositOrder.share0);
        uint256 amount1Desired = tokenShares.sharesToAmount(token1, depositOrder.share1);
        ITwapPair(pair).sync();
        (amount0Left, amount1Left) = AddLiquidity.addLiquidityAndMint(
            pair,
            depositOrder.to,
            token0,
            token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _refundDeposit(
        address to,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) private {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, to, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, to, amount1);
        }
    }

    function _executeWithdraw(Orders.WithdrawOrder memory withdrawOrder) external {
        require(msg.sender == address(this), 'TD00');
        require(withdrawOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        ITwapPair(pair).sync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);

        (uint256 wethAmount, uint256 amount0, uint256 amount1) = (0, 0, 0);
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to,
                orders.transferGasCosts[address(0)]
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = ITwapPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'TD03');
    }

    function _executeBuy(Orders.BuyOrder memory buyOrder) external {
        require(msg.sender == address(this), 'TD00');
        require(buyOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(buyOrder.pairId, buyOrder.inverse);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax);
        ITwapPair pair = ITwapPair(pairAddress);
        pair.sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, buyOrder.priceAccumulator, buyOrder.timestamp);
        uint256 amountIn = buyOrder.inverse
            ? pair.getSwapAmount1In(buyOrder.amountOut, priceInfo)
            : pair.getSwapAmount0In(buyOrder.amountOut, priceInfo);
        require(amountInMax >= amountIn, 'TD08');
        if (amountInMax > amountIn) {
            if (tokenIn == tokenShares.weth && buyOrder.unwrap) {
                _forceEtherTransfer(buyOrder.to, amountInMax.sub(amountIn));
            } else {
                TransferHelper.safeTransfer(tokenIn, buyOrder.to, amountInMax.sub(amountIn));
            }
        }
        (uint256 amount0Out, uint256 amount1Out) = buyOrder.inverse
            ? (buyOrder.amountOut, uint256(0))
            : (uint256(0), buyOrder.amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(buyOrder.to, buyOrder.amountOut);
        } else {
            pair.swap(amount0Out, amount1Out, buyOrder.to, priceInfo);
        }
    }

    function _executeSell(Orders.SellOrder memory sellOrder) external {
        require(msg.sender == address(this), 'TD00');
        require(sellOrder.validAfterTimestamp + ORDER_LIFESPAN >= block.timestamp, 'TD04');

        (address pairAddress, address tokenIn, address tokenOut) = _getPairAndTokens(
            sellOrder.pairId,
            sellOrder.inverse
        );
        uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn);
        ITwapPair pair = ITwapPair(pairAddress);
        pair.sync();
        bytes memory priceInfo = encodePriceInfo(pairAddress, sellOrder.priceAccumulator, sellOrder.timestamp);
        uint256 amountOut = sellOrder.inverse
            ? pair.getSwapAmount0Out(amountIn, priceInfo)
            : pair.getSwapAmount1Out(amountIn, priceInfo);
        require(amountOut >= sellOrder.amountOutMin, 'TD37');
        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this), priceInfo);
            _forceEtherTransfer(sellOrder.to, amountOut);
        } else {
            pair.swap(amount0Out, amount1Out, sellOrder.to, priceInfo);
        }
    }

    function _getPairAndTokens(uint32 pairId, bool pairInversed)
        private
        view
        returns (
            address,
            address,
            address
        )
    {
        (address pairAddress, address token0, address token1) = orders.getPairInfo(pairId);
        (address tokenIn, address tokenOut) = pairInversed ? (token1, token0) : (token0, token1);
        return (pairAddress, tokenIn, tokenOut);
    }

    function _forceEtherTransfer(address to, uint256 amount) internal {
        IWETH(tokenShares.weth).withdraw(amount);
        (bool success, ) = to.call{ value: amount, gas: orders.transferGasCosts[address(0)] }('');
        if (!success) {
            tokenShares.onUnwrapFailed(to, amount);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        require(orderType != Orders.OrderType.Empty, 'TD41');
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;

        if (orderType == Orders.OrderType.Deposit) {
            Orders.DepositOrder memory depositOrder = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'TD14'
            );
            if (shouldRefundEth) {
                uint256 value = depositOrder.gasPrice.mul(depositOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(refundLiquidity(pair, to, withdrawOrder.liquidity), 'TD14');
            if (shouldRefundEth) {
                uint256 value = withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            Orders.SellOrder memory sellOrder = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                uint256 value = sellOrder.gasPrice.mul(sellOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD40');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            Orders.BuyOrder memory buyOrder = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap), 'TD14');
            if (shouldRefundEth) {
                uint256 value = buyOrder.gasPrice.mul(buyOrder.gasLimit);
                require(refundEth(payable(to), value), 'TD40');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) external override lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) external override lock {
        require(orders.getOrderStatus(orderId) == Orders.OrderStatus.EnqueuedReady, 'TD52');
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(validAfterTimestamp.sub(orders.delay).add(ORDER_CANCEL_TIME) < block.timestamp, 'TD1C');
        orders.canceled[orderId] = true;
        performRefund(orderType, validAfterTimestamp, orderId, true);
    }

    function encodePriceInfo(
        address pair,
        uint256 priceAccumulator,
        uint32 priceTimestamp
    ) internal view returns (bytes memory data) {
        uint256 price = ITwapOracle(ITwapPair(pair).oracle()).getAveragePrice(priceAccumulator, priceTimestamp);
        // Pack everything as 32 bytes / uint256 to simplify decoding
        data = abi.encode(price);
    }

    receive() external payable {}
}
