// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Constants.sol";
import "./OrderBookLib.sol";
import "./ProtocolTypes.sol";
import "./LendingMarketStorage.sol";
import "./RoundingUint256.sol";
import "./ILendingMarket.sol";

library OrderBookLogic {
    using OrderBookLib for OrderBookLib.OrderBook;
    using RoundingUint256 for uint256;

    error InvalidOrderFeeRate();
    error InvalidCircuitBreakerLimitRange();
    error OrderBookNotMatured();

    event OrderFeeRateUpdated(bytes32 ccy, uint256 previousRate, uint256 rate);
    event CircuitBreakerLimitRangeUpdated(bytes32 ccy, uint256 previousRate, uint256 rate);
    event OrderBookCreated(uint8 orderBookId, uint256 maturity, uint256 openingDate);

    event ItayoseExecuted(
        bytes32 ccy,
        uint256 maturity,
        uint256 openingUnitPrice,
        uint256 lastLendUnitPrice,
        uint256 lastBorrowUnitPrice,
        uint256 offsetAmount
    );

    function isReady(uint8 _orderBookId) public view returns (bool) {
        return Storage.slot().isReady[_getOrderBook(_orderBookId).maturity];
    }

    function isMatured(uint8 _orderBookId) public view returns (bool) {
        return _getOrderBook(_orderBookId).isMatured();
    }

    function isOpened(uint8 _orderBookId) public view returns (bool) {
        return
            isReady(_orderBookId) &&
            !isMatured(_orderBookId) &&
            block.timestamp >= _getOrderBook(_orderBookId).openingDate;
    }

    function isItayosePeriod(uint8 _orderBookId) public view returns (bool) {
        return
            block.timestamp >=
            (_getOrderBook(_orderBookId).openingDate - OrderBookLib.ITAYOSE_PERIOD) &&
            !isReady(_orderBookId);
    }

    function isPreOrderPeriod(uint8 _orderBookId) public view returns (bool) {
        OrderBookLib.OrderBook storage orderBook = _getOrderBook(_orderBookId);
        return
            block.timestamp >= orderBook.preOpeningDate &&
            block.timestamp < (orderBook.openingDate - OrderBookLib.ITAYOSE_PERIOD);
    }

    function getOrderBookDetail(
        uint8 _orderBookId
    )
        public
        view
        returns (bytes32 ccy, uint256 maturity, uint256 openingDate, uint256 preOpeningDate)
    {
        OrderBookLib.OrderBook storage orderBook = _getOrderBook(_orderBookId);

        ccy = Storage.slot().ccy;
        maturity = orderBook.maturity;
        openingDate = orderBook.openingDate;
        preOpeningDate = orderBook.preOpeningDate;
    }

    function getLastOrderTimestamp(uint8 _orderBookId) external view returns (uint48) {
        return _getOrderBook(_orderBookId).lastOrderTimestamp;
    }

    function getBlockUnitPriceHistory(
        uint8 _orderBookId
    ) external view returns (uint256[] memory unitPrices, uint48 timestamp) {
        return _getOrderBook(_orderBookId).getBlockUnitPriceHistory(true);
    }

    function getMarketUnitPrice(uint8 _orderBookId) external view returns (uint256) {
        return _getOrderBook(_orderBookId).getMarketUnitPrice(true);
    }

    function getBlockUnitPriceAverage(
        uint8 _orderBookId,
        uint256 _count
    ) external view returns (uint256) {
        return _getOrderBook(_orderBookId).getBlockUnitPriceAverage(_count, true);
    }

    function getCircuitBreakerThresholds(
        uint8 _orderBookId
    ) external view returns (uint256 maxLendUnitPrice, uint256 minBorrowUnitPrice) {
        maxLendUnitPrice = _getOrderBook(_orderBookId).getLendCircuitBreakerThreshold(
            Storage.slot().circuitBreakerLimitRange,
            true
        );
        minBorrowUnitPrice = _getOrderBook(_orderBookId).getBorrowCircuitBreakerThreshold(
            Storage.slot().circuitBreakerLimitRange,
            true
        );
    }

    function getBestLendUnitPrice(uint8 _orderBookId) public view returns (uint256) {
        return _getOrderBook(_orderBookId).getBestLendUnitPrice();
    }

    function getBestLendUnitPrices(
        uint8[] memory _orderBookIds
    ) external view returns (uint256[] memory unitPrices) {
        unitPrices = new uint256[](_orderBookIds.length);

        for (uint256 i; i < _orderBookIds.length; i++) {
            unitPrices[i] = _getOrderBook(_orderBookIds[i]).getBestLendUnitPrice();
        }
    }

    function getBestBorrowUnitPrice(uint8 _orderBookId) public view returns (uint256) {
        return _getOrderBook(_orderBookId).getBestBorrowUnitPrice();
    }

    function getBestBorrowUnitPrices(
        uint8[] memory _orderBookIds
    ) external view returns (uint256[] memory unitPrices) {
        unitPrices = new uint256[](_orderBookIds.length);

        for (uint256 i; i < _orderBookIds.length; i++) {
            unitPrices[i] = _getOrderBook(_orderBookIds[i]).getBestBorrowUnitPrice();
        }
    }

    function getBorrowOrderBook(
        uint8 _orderBookId,
        uint256 _start,
        uint256 _limit
    )
        external
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        )
    {
        return _getOrderBook(_orderBookId).getBorrowOrderBook(_start, _limit);
    }

    function getLendOrderBook(
        uint8 _orderBookId,
        uint256 _start,
        uint256 _limit
    )
        external
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        )
    {
        return _getOrderBook(_orderBookId).getLendOrderBook(_start, _limit);
    }

    function getItayoseEstimation(
        uint8 _orderBookId
    )
        external
        view
        returns (
            uint256 openingUnitPrice,
            uint256 lastLendUnitPrice,
            uint256 lastBorrowUnitPrice,
            uint256 totalOffsetAmount
        )
    {
        return _getOrderBook(_orderBookId).calculateItayoseResult();
    }

    function getMaturities(
        uint8[] memory _orderBookIds
    ) public view returns (uint256[] memory maturities) {
        maturities = new uint256[](_orderBookIds.length);

        for (uint256 i; i < _orderBookIds.length; i++) {
            maturities[i] = _getOrderBook(_orderBookIds[i]).maturity;
        }
    }

    function updateOrderFeeRate(uint256 _orderFeeRate) external {
        if (_orderFeeRate >= Constants.PCT_DIGIT) revert InvalidOrderFeeRate();

        uint256 previousRate = Storage.slot().orderFeeRate;

        if (_orderFeeRate != previousRate) {
            Storage.slot().orderFeeRate = _orderFeeRate;

            emit OrderFeeRateUpdated(Storage.slot().ccy, previousRate, _orderFeeRate);
        }
    }

    function updateCircuitBreakerLimitRange(uint256 _cbLimitRange) external {
        if (_cbLimitRange >= Constants.PCT_DIGIT) revert InvalidCircuitBreakerLimitRange();

        uint256 previousRange = Storage.slot().circuitBreakerLimitRange;

        if (_cbLimitRange != previousRange) {
            Storage.slot().circuitBreakerLimitRange = _cbLimitRange;

            emit CircuitBreakerLimitRangeUpdated(Storage.slot().ccy, previousRange, _cbLimitRange);
        }
    }

    function createOrderBook(
        uint256 _maturity,
        uint256 _openingDate,
        uint256 _preOpeningDate
    ) public returns (uint8 orderBookId) {
        orderBookId = _nextOrderBookId();

        Storage.slot().isReady[_maturity] = _getOrderBook(orderBookId).initialize(
            _maturity,
            _openingDate,
            _preOpeningDate
        );

        emit OrderBookCreated(orderBookId, _maturity, _openingDate);
    }

    function executeAutoRoll(
        uint8 _maturedOrderBookId,
        uint8 _destinationOrderBookId,
        uint256 _newMaturity,
        uint256 _openingDate,
        uint256 _autoRollUnitPrice
    ) external {
        OrderBookLib.OrderBook storage maturedOrderBook = Storage.slot().orderBooks[
            _maturedOrderBookId
        ];
        if (!maturedOrderBook.isMatured()) revert OrderBookNotMatured();

        Storage.slot().isReady[_newMaturity] = maturedOrderBook.initialize(
            _newMaturity,
            _openingDate,
            _openingDate - OrderBookLib.PRE_ORDER_BASE_PERIOD
        );

        OrderBookLib.OrderBook storage destinationOrderBook = Storage.slot().orderBooks[
            _destinationOrderBookId
        ];

        // NOTE: The auto-roll destination order book has no market unit price if the order has never been filled before.
        // In this case, the market unit price is updated with the unit price of the auto-roll.
        if (destinationOrderBook.getMarketUnitPrice(false) == 0) {
            destinationOrderBook.setInitialBlockUnitPrice(_autoRollUnitPrice);
        }
    }

    function executeItayoseCall(
        uint8 _orderBookId
    )
        external
        returns (
            uint256 openingUnitPrice,
            uint256 totalOffsetAmount,
            uint256 openingDate,
            PartiallyFilledOrder memory partiallyFilledLendingOrder,
            PartiallyFilledOrder memory partiallyFilledBorrowingOrder
        )
    {
        uint256 lastLendUnitPrice;
        uint256 lastBorrowUnitPrice;
        OrderBookLib.OrderBook storage orderBook = _getOrderBook(_orderBookId);

        (openingUnitPrice, lastLendUnitPrice, lastBorrowUnitPrice, totalOffsetAmount) = orderBook
            .calculateItayoseResult();

        if (totalOffsetAmount > 0) {
            ProtocolTypes.Side[2] memory sides = [
                ProtocolTypes.Side.LEND,
                ProtocolTypes.Side.BORROW
            ];

            for (uint256 i; i < sides.length; i++) {
                ProtocolTypes.Side partiallyFilledOrderSide;
                PartiallyFilledOrder memory partiallyFilledOrder;
                FilledOrder memory filledOrder;
                (filledOrder, partiallyFilledOrder, , ) = orderBook.fillOrders(
                    sides[i],
                    totalOffsetAmount,
                    0,
                    0
                );

                if (filledOrder.futureValue > 0) {
                    orderBook.setInitialBlockUnitPrice(openingUnitPrice);
                }

                if (partiallyFilledOrder.futureValue > 0) {
                    if (sides[i] == ProtocolTypes.Side.LEND) {
                        partiallyFilledOrderSide = ProtocolTypes.Side.BORROW;
                        partiallyFilledBorrowingOrder = partiallyFilledOrder;
                    } else {
                        partiallyFilledOrderSide = ProtocolTypes.Side.LEND;
                        partiallyFilledLendingOrder = partiallyFilledOrder;
                    }
                }
            }

            emit ItayoseExecuted(
                Storage.slot().ccy,
                orderBook.maturity,
                openingUnitPrice,
                lastLendUnitPrice,
                lastBorrowUnitPrice,
                totalOffsetAmount
            );
        }

        Storage.slot().isReady[orderBook.maturity] = true;
        Storage.slot().itayoseLogs[orderBook.maturity] = ItayoseLog(
            openingUnitPrice,
            lastLendUnitPrice,
            lastBorrowUnitPrice
        );
        openingDate = orderBook.openingDate;
    }

    function _nextOrderBookId() internal returns (uint8) {
        Storage.slot().lastOrderBookId++;
        return Storage.slot().lastOrderBookId;
    }

    function _getOrderBook(
        uint8 _orderBookId
    ) private view returns (OrderBookLib.OrderBook storage) {
        return Storage.slot().orderBooks[_orderBookId];
    }
}
