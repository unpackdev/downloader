// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Constants.sol";
import "./ProtocolTypes.sol";
import "./OrderStatisticsTreeLib.sol";
import "./RoundingUint256.sol";

struct PlacedOrder {
    ProtocolTypes.Side side;
    uint256 unitPrice;
    uint256 maturity;
    uint256 timestamp;
}

struct FilledOrder {
    uint256 amount;
    uint256 unitPrice;
    uint256 futureValue;
    uint256 ignoredAmount;
}

struct PartiallyFilledOrder {
    uint48 orderId;
    address maker;
    uint256 amount;
    uint256 futureValue;
}

library OrderBookLib {
    using OrderStatisticsTreeLib for OrderStatisticsTreeLib.Tree;
    using RoundingUint256 for uint256;

    uint256 public constant PRE_ORDER_BASE_PERIOD = 7 days;
    uint256 public constant ITAYOSE_PERIOD = 1 hours;
    uint256 public constant CIRCUIT_BREAKER_MINIMUM_LEND_RANGE = 700;
    uint256 public constant CIRCUIT_BREAKER_MINIMUM_BORROW_RANGE = 200;

    error EmptyOrderBook();
    error PastMaturityOrderExists();

    struct OrderBook {
        uint256 maturity;
        uint256 openingDate;
        uint256 preOpeningDate;
        uint48 lastOrderId;
        uint48 lastOrderTimestamp;
        bool isReliableBlock;
        // Micro slots for block unit price history
        uint80 blockUnitPriceHistory;
        uint48 lastBlockUnitPriceTimestamp;
        uint256 blockTotalAmount;
        uint256 blockTotalFutureValue;
        mapping(address user => uint48[] orderIds) activeLendOrderIds;
        mapping(address user => uint48[] orderIds) activeBorrowOrderIds;
        // Maturity when user last executes order
        mapping(address user => uint256 maturity) userCurrentMaturities;
        // Micro slots for order
        mapping(uint48 orderId => uint256 slots) orders;
        mapping(uint48 orderId => bool isPreOrder) isPreOrder;
        mapping(uint256 maturity => OrderStatisticsTreeLib.Tree orders) lendOrders;
        mapping(uint256 maturity => OrderStatisticsTreeLib.Tree orders) borrowOrders;
    }

    function initialize(
        OrderBook storage self,
        uint256 _maturity,
        uint256 _openingDate,
        uint256 _preOpeningDate
    ) internal returns (bool isReady) {
        self.maturity = _maturity;
        self.openingDate = _openingDate;
        self.preOpeningDate = _preOpeningDate;

        self.blockTotalAmount = 0;
        self.blockTotalFutureValue = 0;
        self.blockUnitPriceHistory = 0;
        self.lastOrderTimestamp = 0;
        self.lastBlockUnitPriceTimestamp = 0;
        self.isReliableBlock = false;

        if (block.timestamp >= (_openingDate - ITAYOSE_PERIOD)) {
            isReady = true;
        }
    }

    function isMatured(OrderBook storage self) internal view returns (bool) {
        return block.timestamp >= self.maturity;
    }

    function getBestBorrowUnitPrice(OrderBook storage self) internal view returns (uint256) {
        return self.lendOrders[self.maturity].last();
    }

    function getBestLendUnitPrice(OrderBook storage self) internal view returns (uint256) {
        uint256 unitPrice = self.borrowOrders[self.maturity].first();
        return unitPrice == 0 ? Constants.PRICE_DIGIT : unitPrice;
    }

    function hasBorrowOrder(OrderBook storage self, address _user) internal view returns (bool) {
        return self.activeBorrowOrderIds[_user].length != 0;
    }

    function hasLendOrder(OrderBook storage self, address _user) internal view returns (bool) {
        return self.activeLendOrderIds[_user].length != 0;
    }

    function getOrder(
        OrderBook storage self,
        uint48 _orderId
    ) internal view returns (PlacedOrder memory order) {
        (
            ProtocolTypes.Side side,
            uint256 unitPrice,
            uint256 maturity,
            uint256 timestamp
        ) = _unpackOrder(self.orders[_orderId]);
        order = PlacedOrder(side, unitPrice, maturity, timestamp);
    }

    function getBlockUnitPriceHistory(
        OrderBook storage self,
        bool _isReadOnly
    ) internal view returns (uint256[] memory prices, uint48 timestamp) {
        prices = _unpackBlockUnitPriceHistory(self.blockUnitPriceHistory);

        // NOTE: If an order is in the first block of the order book, the block unit price history is empty.
        // In this case, the first history record is calculated from the current block total amount and total future value
        // along with the `getMarketUnitPrice` function logic.
        if (
            (self.lastOrderTimestamp != block.timestamp || prices[0] == 0 || _isReadOnly) &&
            self.isReliableBlock
        ) {
            for (uint256 i = prices.length - 1; i > 0; i--) {
                prices[i] = prices[i - 1];
            }

            prices[0] = (self.blockTotalAmount * Constants.PRICE_DIGIT).div(
                self.blockTotalFutureValue
            );
            timestamp = self.lastOrderTimestamp;
        } else {
            timestamp = self.lastBlockUnitPriceTimestamp;
        }
    }

    function getMarketUnitPrice(
        OrderBook storage self,
        bool _isReadOnly
    ) internal view returns (uint256 unitPrice) {
        unitPrice = _unpackBlockUnitPriceHistory(self.blockUnitPriceHistory)[0];

        // NOTE: If an order is in the first block of the order book, the block unit price history is empty.
        // In this case, the market unit price is calculated from the current block total amount and total future value
        // to avoid unwinding or liquidation the order in the same block using 0 as the market unit price.
        if (
            (self.lastOrderTimestamp != block.timestamp || unitPrice == 0 || _isReadOnly) &&
            self.isReliableBlock
        ) {
            unitPrice = (self.blockTotalAmount * Constants.PRICE_DIGIT).div(
                self.blockTotalFutureValue
            );
        }
    }

    function getBlockUnitPriceAverage(
        OrderBook storage self,
        uint256 maxCount,
        bool _isReadOnly
    ) internal view returns (uint256 unitPrice) {
        uint256[] memory unitPrices = _unpackBlockUnitPriceHistory(self.blockUnitPriceHistory);
        uint256 length = unitPrices.length;
        uint256 sum;
        uint256 count;

        if ((self.lastOrderTimestamp != block.timestamp || _isReadOnly) && self.isReliableBlock) {
            sum = (self.blockTotalAmount * Constants.PRICE_DIGIT).div(self.blockTotalFutureValue);
            count = 1;
            maxCount--;
        }

        for (uint256 i; i < maxCount; i++) {
            if (i >= length || unitPrices[i] == 0) {
                break;
            }

            sum += unitPrices[i];
            count++;
        }

        unitPrice = count > 0 ? sum.div(count) : 0;
    }

    function getLendOrderBook(
        OrderBook storage self,
        uint256 _start,
        uint256 _limit
    )
        internal
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        )
    {
        unitPrices = new uint256[](_limit);
        amounts = new uint256[](_limit);
        quantities = new uint256[](_limit);

        uint256 unitPrice;

        if (_start == 0) {
            unitPrice = self.lendOrders[self.maturity].last();
        } else {
            (bool exists, uint256 parent) = self.lendOrders[self.maturity].search(_start);

            if (exists) {
                unitPrice = _start;
            } else if (parent < _start) {
                unitPrice = parent;
            } else {
                unitPrice = self.lendOrders[self.maturity].prev(parent);
            }
        }

        unitPrices[0] = unitPrice;
        amounts[0] = self.lendOrders[self.maturity].getNodeTotalAmount(unitPrice);
        quantities[0] = self.lendOrders[self.maturity].getNodeCount(unitPrice);

        for (uint256 i = 1; i < unitPrices.length; i++) {
            if (unitPrice == 0) {
                break;
            }

            unitPrice = self.lendOrders[self.maturity].prev(unitPrice);
            unitPrices[i] = unitPrice;
            amounts[i] = self.lendOrders[self.maturity].getNodeTotalAmount(unitPrice);
            quantities[i] = self.lendOrders[self.maturity].getNodeCount(unitPrice);
        }

        if (unitPrice != 0) {
            next = self.lendOrders[self.maturity].prev(unitPrice);
        }
    }

    function getBorrowOrderBook(
        OrderBook storage self,
        uint256 _start,
        uint256 _limit
    )
        internal
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        )
    {
        unitPrices = new uint256[](_limit);
        amounts = new uint256[](_limit);
        quantities = new uint256[](_limit);

        uint256 unitPrice;

        if (_start == 0) {
            unitPrice = self.borrowOrders[self.maturity].first();
        } else {
            (bool exists, uint256 parent) = self.borrowOrders[self.maturity].search(_start);

            if (exists) {
                unitPrice = _start;
            } else if (parent > _start) {
                unitPrice = parent;
            } else {
                unitPrice = self.borrowOrders[self.maturity].next(parent);
            }
        }

        unitPrices[0] = unitPrice;
        amounts[0] = self.borrowOrders[self.maturity].getNodeTotalAmount(unitPrice);
        quantities[0] = self.borrowOrders[self.maturity].getNodeCount(unitPrice);

        for (uint256 i = 1; i < unitPrices.length; i++) {
            if (unitPrice == 0) {
                break;
            }

            unitPrice = self.borrowOrders[self.maturity].next(unitPrice);
            unitPrices[i] = unitPrice;
            amounts[i] = self.borrowOrders[self.maturity].getNodeTotalAmount(unitPrice);
            quantities[i] = self.borrowOrders[self.maturity].getNodeCount(unitPrice);
        }

        if (unitPrice != 0) {
            next = self.borrowOrders[self.maturity].next(unitPrice);
        }
    }

    function getLendOrderIds(
        OrderBook storage self,
        address _user
    ) internal view returns (uint48[] memory activeOrderIds, uint48[] memory inActiveOrderIds) {
        uint256 activeOrderCount = 0;
        uint256 inActiveOrderCount = 0;
        uint256 userMaturity = self.userCurrentMaturities[_user];
        bool isPastMaturity = userMaturity != self.maturity;

        uint48[] memory orderIds = self.activeLendOrderIds[_user];
        uint256 orderIdLength = orderIds.length;
        activeOrderIds = new uint48[](isPastMaturity ? 0 : orderIdLength);
        inActiveOrderIds = new uint48[](orderIdLength);

        for (uint256 i; i < orderIdLength; i++) {
            uint48 orderId = orderIds[i];
            (, uint256 unitPrice, , ) = _unpackOrder(self.orders[orderId]);

            if (!self.lendOrders[userMaturity].isActiveOrderId(unitPrice, orderId)) {
                unchecked {
                    inActiveOrderCount += 1;
                }
                inActiveOrderIds[i - activeOrderCount] = orderId;
                if (!isPastMaturity) {
                    assembly {
                        mstore(activeOrderIds, sub(mload(activeOrderIds), 1))
                    }
                }
            } else {
                if (!isPastMaturity) {
                    unchecked {
                        activeOrderCount += 1;
                    }
                    activeOrderIds[i - inActiveOrderCount] = orderId;
                }
                assembly {
                    mstore(inActiveOrderIds, sub(mload(inActiveOrderIds), 1))
                }
            }
        }
    }

    function getBorrowOrderIds(
        OrderBook storage self,
        address _user
    ) internal view returns (uint48[] memory activeOrderIds, uint48[] memory inActiveOrderIds) {
        uint256 activeOrderCount = 0;
        uint256 inActiveOrderCount = 0;
        uint256 userMaturity = self.userCurrentMaturities[_user];
        bool isPastMaturity = userMaturity != self.maturity;

        uint48[] memory orderIds = self.activeBorrowOrderIds[_user];
        uint256 orderIdLength = orderIds.length;
        activeOrderIds = new uint48[](isPastMaturity ? 0 : orderIdLength);
        inActiveOrderIds = new uint48[](orderIdLength);

        for (uint256 i; i < orderIdLength; i++) {
            uint48 orderId = orderIds[i];
            (, uint256 unitPrice, , ) = _unpackOrder(self.orders[orderId]);

            if (!self.borrowOrders[userMaturity].isActiveOrderId(unitPrice, orderId)) {
                unchecked {
                    inActiveOrderCount += 1;
                }
                inActiveOrderIds[i - activeOrderCount] = orderId;
                if (!isPastMaturity) {
                    assembly {
                        mstore(activeOrderIds, sub(mload(activeOrderIds), 1))
                    }
                }
            } else {
                unchecked {
                    activeOrderCount += 1;
                }
                if (!isPastMaturity) {
                    activeOrderIds[i - inActiveOrderCount] = orderId;
                }
                assembly {
                    mstore(inActiveOrderIds, sub(mload(inActiveOrderIds), 1))
                }
            }
        }
    }

    function calculateFilledAmount(
        OrderBook storage self,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    )
        internal
        view
        returns (uint256 lastUnitPrice, uint256 filledAmount, uint256 filledAmountInFV)
    {
        if (_amount == 0) return (0, 0, 0);

        if (_side == ProtocolTypes.Side.LEND) {
            return
                self.borrowOrders[self.maturity].calculateDroppedAmountFromLeft(
                    _amount,
                    0,
                    _unitPrice
                );
        } else {
            return
                self.lendOrders[self.maturity].calculateDroppedAmountFromRight(
                    _amount,
                    0,
                    _unitPrice
                );
        }
    }

    function updateUserMaturity(OrderBook storage self, address _user) internal {
        uint256 userMaturity = self.userCurrentMaturities[_user];
        uint256 orderBookMaturity = self.maturity;

        if (userMaturity != orderBookMaturity) {
            if (
                self.activeLendOrderIds[_user].length > 0 ||
                self.activeBorrowOrderIds[_user].length > 0
            ) {
                revert PastMaturityOrderExists();
            }

            self.userCurrentMaturities[_user] = orderBookMaturity;
        }
    }

    function placeOrder(
        OrderBook storage self,
        ProtocolTypes.Side _side,
        address _user,
        uint256 _amount,
        uint256 _unitPrice
    ) internal returns (uint48 orderId) {
        orderId = _nextOrderId(self);
        self.orders[orderId] = _packOrder(_side, _unitPrice, self.maturity, block.timestamp);

        if (_side == ProtocolTypes.Side.LEND) {
            self.lendOrders[self.maturity].insertOrder(_unitPrice, orderId, _user, _amount);
            self.activeLendOrderIds[_user].push(orderId);
        } else if (_side == ProtocolTypes.Side.BORROW) {
            self.borrowOrders[self.maturity].insertOrder(_unitPrice, orderId, _user, _amount);
            self.activeBorrowOrderIds[_user].push(orderId);
        }
    }

    function fillOrders(
        OrderBook storage self,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _amountInFV,
        uint256 _unitPrice
    )
        internal
        returns (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 remainingAmount,
            bool orderExists
        )
    {
        PartiallyRemovedOrder memory partiallyRemovedOrder;

        if (_side == ProtocolTypes.Side.BORROW) {
            OrderStatisticsTreeLib.Tree storage orders = self.lendOrders[self.maturity];
            (
                filledOrder.unitPrice,
                filledOrder.amount,
                filledOrder.futureValue,
                remainingAmount,
                partiallyRemovedOrder
            ) = orders.dropRight(_amount, _amountInFV, _unitPrice);
            orderExists = orders.hasOrders();
        } else if (_side == ProtocolTypes.Side.LEND) {
            OrderStatisticsTreeLib.Tree storage orders = self.borrowOrders[self.maturity];
            (
                filledOrder.unitPrice,
                filledOrder.amount,
                filledOrder.futureValue,
                remainingAmount,
                partiallyRemovedOrder
            ) = orders.dropLeft(_amount, _amountInFV, _unitPrice);
            orderExists = orders.hasOrders();
        }

        partiallyFilledOrder = PartiallyFilledOrder(
            partiallyRemovedOrder.orderId,
            partiallyRemovedOrder.maker,
            partiallyRemovedOrder.amount,
            partiallyRemovedOrder.futureValue
        );
    }

    function setInitialBlockUnitPrice(OrderBook storage self, uint256 _unitPrice) internal {
        self.blockUnitPriceHistory = uint16(_unitPrice);
        self.lastBlockUnitPriceTimestamp = uint48(block.timestamp);
        self.lastOrderTimestamp = uint48(block.timestamp);
    }

    function updateBlockUnitPriceHistory(
        OrderBook storage self,
        uint256 _filledAmount,
        uint256 _filledFutureValue,
        uint256 _minimumReliableAmount
    ) internal {
        uint256 latestBlockUnitPrice = _unpackBlockUnitPriceHistory(self.blockUnitPriceHistory)[0];

        if (self.lastOrderTimestamp != block.timestamp) {
            if (self.isReliableBlock) {
                latestBlockUnitPrice = (self.blockTotalAmount * Constants.PRICE_DIGIT).div(
                    self.blockTotalFutureValue
                );

                // Remove the oldest block unit price and add the latest block unit price
                self.blockUnitPriceHistory =
                    uint16(latestBlockUnitPrice) |
                    (self.blockUnitPriceHistory << 16);
                self.lastBlockUnitPriceTimestamp = uint48(block.timestamp);
            }

            self.lastOrderTimestamp = uint48(block.timestamp);
            self.blockTotalAmount = _filledAmount;
            self.blockTotalFutureValue = _filledFutureValue;
            self.isReliableBlock = false;
        } else {
            self.blockTotalAmount += _filledAmount;
            self.blockTotalFutureValue += _filledFutureValue;
        }

        if (
            self.blockTotalAmount >= _minimumReliableAmount ||
            (self.blockTotalAmount > 0 && latestBlockUnitPrice == 0)
        ) {
            self.isReliableBlock = true;
        }
    }

    function removeOrder(
        OrderBook storage self,
        address _user,
        uint48 _orderId
    ) internal returns (ProtocolTypes.Side, uint256, uint256) {
        (ProtocolTypes.Side side, uint256 unitPrice, , ) = _unpackOrder(self.orders[_orderId]);
        uint256 removedAmount;

        if (side == ProtocolTypes.Side.LEND) {
            removedAmount = self.lendOrders[self.maturity].removeOrder(unitPrice, _orderId);
            _removeOrderIdFromOrders(self.activeLendOrderIds[_user], _orderId);
        } else if (side == ProtocolTypes.Side.BORROW) {
            removedAmount = self.borrowOrders[self.maturity].removeOrder(unitPrice, _orderId);
            _removeOrderIdFromOrders(self.activeBorrowOrderIds[_user], _orderId);
        }

        delete self.orders[_orderId];

        return (side, removedAmount, unitPrice);
    }

    function calculateItayoseResult(
        OrderBook storage self
    )
        internal
        view
        returns (
            uint256 openingUnitPrice,
            uint256 lastLendUnitPrice,
            uint256 lastBorrowUnitPrice,
            uint256 totalOffsetAmount
        )
    {
        uint256 lendUnitPrice = self.lendOrders[self.maturity].last();
        uint256 borrowUnitPrice = self.borrowOrders[self.maturity].first();
        uint256 lendAmount = self.lendOrders[self.maturity].getNodeTotalAmount(lendUnitPrice);
        uint256 borrowAmount = self.borrowOrders[self.maturity].getNodeTotalAmount(borrowUnitPrice);

        OrderStatisticsTreeLib.Tree storage borrowOrders = self.borrowOrders[self.maturity];
        OrderStatisticsTreeLib.Tree storage lendOrders = self.lendOrders[self.maturity];

        // Return 0 if no orders is filled
        if (borrowUnitPrice > lendUnitPrice || borrowUnitPrice == 0 || lendUnitPrice == 0) {
            return (0, 0, 0, 0);
        }

        while (borrowUnitPrice <= lendUnitPrice && borrowUnitPrice > 0 && lendUnitPrice > 0) {
            lastLendUnitPrice = lendUnitPrice;
            lastBorrowUnitPrice = borrowUnitPrice;

            if (lendAmount > borrowAmount) {
                openingUnitPrice = lendUnitPrice;
                totalOffsetAmount += borrowAmount;
                lendAmount -= borrowAmount;
                borrowUnitPrice = borrowOrders.next(borrowUnitPrice);
                borrowAmount = borrowOrders.getNodeTotalAmount(borrowUnitPrice);
            } else if (lendAmount < borrowAmount) {
                openingUnitPrice = borrowUnitPrice;
                totalOffsetAmount += lendAmount;
                borrowAmount -= lendAmount;
                lendUnitPrice = lendOrders.prev(lendUnitPrice);
                lendAmount = lendOrders.getNodeTotalAmount(lendUnitPrice);
            } else {
                openingUnitPrice = (lendUnitPrice + borrowUnitPrice).div(2);
                totalOffsetAmount += lendAmount;
                lendUnitPrice = lendOrders.prev(lendUnitPrice);
                borrowUnitPrice = borrowOrders.next(borrowUnitPrice);
                lendAmount = lendOrders.getNodeTotalAmount(lendUnitPrice);
                borrowAmount = borrowOrders.getNodeTotalAmount(borrowUnitPrice);
            }
        }
    }

    function getOrderExecutionConditions(
        OrderBook storage self,
        ProtocolTypes.Side _side,
        uint256 _unitPrice,
        uint256 _circuitBreakerLimitRange,
        bool _isReadOnly
    )
        internal
        view
        returns (
            bool isFilled,
            uint256 executedUnitPrice,
            bool ignoreRemainingAmount,
            bool orderExists
        )
    {
        bool isLend = _side == ProtocolTypes.Side.LEND;
        uint256 cbThresholdUnitPrice;
        uint256 bestUnitPrice;

        if (isLend) {
            bestUnitPrice = self.borrowOrders[self.maturity].first();
            cbThresholdUnitPrice = getLendCircuitBreakerThreshold(
                self,
                _circuitBreakerLimitRange,
                _isReadOnly
            );
        } else {
            bestUnitPrice = self.lendOrders[self.maturity].last();
            cbThresholdUnitPrice = getBorrowCircuitBreakerThreshold(
                self,
                _circuitBreakerLimitRange,
                _isReadOnly
            );
        }

        orderExists = bestUnitPrice != 0;

        if (
            _unitPrice == 0 ||
            (orderExists &&
                cbThresholdUnitPrice != 0 &&
                ((isLend && _unitPrice > cbThresholdUnitPrice) ||
                    (!isLend && _unitPrice < cbThresholdUnitPrice)))
        ) {
            executedUnitPrice = cbThresholdUnitPrice;
            ignoreRemainingAmount = true;
        } else {
            executedUnitPrice = _unitPrice;
            ignoreRemainingAmount = false;
        }

        if (orderExists) {
            isFilled = isLend
                ? bestUnitPrice <= executedUnitPrice
                : bestUnitPrice >= executedUnitPrice;
        }
    }

    function getLendCircuitBreakerThreshold(
        OrderBook storage self,
        uint256 _circuitBreakerLimitRange,
        bool _isReadOnly
    ) internal view returns (uint256 cbThresholdUnitPrice) {
        uint256 blockUnitPriceAverage = getBlockUnitPriceAverage(self, 3, _isReadOnly);
        cbThresholdUnitPrice = (blockUnitPriceAverage *
            (Constants.PCT_DIGIT + _circuitBreakerLimitRange * 2)).div(Constants.PCT_DIGIT);

        if (cbThresholdUnitPrice > Constants.PRICE_DIGIT || blockUnitPriceAverage == 0) {
            cbThresholdUnitPrice = Constants.PRICE_DIGIT;
        } else if (
            cbThresholdUnitPrice < blockUnitPriceAverage + CIRCUIT_BREAKER_MINIMUM_LEND_RANGE
        ) {
            cbThresholdUnitPrice = blockUnitPriceAverage + CIRCUIT_BREAKER_MINIMUM_LEND_RANGE;
        }
    }

    function getBorrowCircuitBreakerThreshold(
        OrderBook storage self,
        uint256 _circuitBreakerLimitRange,
        bool _isReadOnly
    ) internal view returns (uint256 cbThresholdUnitPrice) {
        uint256 blockUnitPriceAverage = getBlockUnitPriceAverage(self, 5, _isReadOnly);
        cbThresholdUnitPrice = (blockUnitPriceAverage *
            (Constants.PCT_DIGIT - _circuitBreakerLimitRange)).div(Constants.PCT_DIGIT);

        if (
            cbThresholdUnitPrice == 0 ||
            blockUnitPriceAverage == 0 ||
            blockUnitPriceAverage <= CIRCUIT_BREAKER_MINIMUM_BORROW_RANGE
        ) {
            cbThresholdUnitPrice = 1;
        } else if (
            blockUnitPriceAverage < cbThresholdUnitPrice + CIRCUIT_BREAKER_MINIMUM_BORROW_RANGE
        ) {
            cbThresholdUnitPrice = blockUnitPriceAverage - CIRCUIT_BREAKER_MINIMUM_BORROW_RANGE;
        }
    }

    /**
     * @notice Increases and returns id of last order in order book.
     * @return The new order id
     */
    function _nextOrderId(OrderBook storage self) private returns (uint48) {
        self.lastOrderId++;
        return self.lastOrderId;
    }

    function _removeOrderIdFromOrders(uint48[] storage orders, uint256 orderId) private {
        uint256 lastOrderIndex = orders.length - 1;
        for (uint256 i; i <= lastOrderIndex; i++) {
            if (orders[i] == orderId) {
                if (i != lastOrderIndex) {
                    uint48 lastOrderId = orders[lastOrderIndex];
                    orders[i] = lastOrderId;
                }

                orders.pop();
                break;
            }
        }
    }

    /**
     * @notice Packs order parameters into uint256
     */
    function _packOrder(
        ProtocolTypes.Side _side,
        uint256 _unitPrice,
        uint256 _maturity,
        uint256 _timestamp
    ) private pure returns (uint256) {
        return uint256(_side) | (_unitPrice << 8) | (_maturity << 24) | (_timestamp << 88);
    }

    /**
     * @notice Unpacks order parameters from uint256
     */
    function _unpackOrder(
        uint256 _order
    )
        private
        pure
        returns (ProtocolTypes.Side side, uint256 unitPrice, uint256 maturity, uint256 timestamp)
    {
        side = ProtocolTypes.Side(uint8(_order));
        unitPrice = uint16(_order >> 8);
        maturity = uint64(_order >> 24);
        timestamp = uint64(_order >> 88);
    }

    function _unpackBlockUnitPriceHistory(
        uint80 _blockUnitPriceHistory
    ) private pure returns (uint256[] memory prices) {
        prices = new uint256[](5);

        prices[0] = uint16(_blockUnitPriceHistory);
        prices[1] = uint16(_blockUnitPriceHistory >> 16);
        prices[2] = uint16(_blockUnitPriceHistory >> 32);
        prices[3] = uint16(_blockUnitPriceHistory >> 48);
        prices[4] = uint16(_blockUnitPriceHistory >> 64);
    }
}
