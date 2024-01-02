// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ProtocolTypes.sol";
import "./LendingMarketStorage.sol";
import "./OrderBookLib.sol";

interface ILendingMarket {
    error NoOrderExists();
    error CallerNotMaker();
    error MarketNotOpened();
    error AlreadyItayosePeriod();
    error NotItayosePeriod();
    error NotPreOrderPeriod();

    function getOrderBookDetail(
        uint8 orderBookId
    )
        external
        view
        returns (bytes32 ccy, uint256 maturity, uint256 openingDate, uint256 preOpeningDate);

    function getCircuitBreakerThresholds(
        uint8 orderBookId
    )
        external
        view
        returns (uint256 lendCircuitBreakerThreshold, uint256 borrowCircuitBreakerThreshold);

    function getBestLendUnitPrice(uint8 orderBookId) external view returns (uint256 unitPrice);

    function getBestLendUnitPrices(
        uint8[] calldata orderBookIds
    ) external view returns (uint256[] memory);

    function getBestBorrowUnitPrice(uint8 orderBookId) external view returns (uint256 unitPrice);

    function getBestBorrowUnitPrices(
        uint8[] calldata orderBookIds
    ) external view returns (uint256[] memory);

    function getMarketUnitPrice(uint8 orderBookId) external view returns (uint256);

    function getLastOrderTimestamp(uint8 orderBookId) external view returns (uint48);

    function getBlockUnitPriceHistory(
        uint8 orderBookId
    ) external view returns (uint256[] memory unitPrices, uint48 timestamp);

    function getBlockUnitPriceAverage(
        uint8 orderBookId,
        uint256 count
    ) external view returns (uint256);

    function getBorrowOrderBook(
        uint8 orderBookId,
        uint256 start,
        uint256 limit
    )
        external
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        );

    function getLendOrderBook(
        uint8 orderBookId,
        uint256 start,
        uint256 limit
    )
        external
        view
        returns (
            uint256[] memory unitPrices,
            uint256[] memory amounts,
            uint256[] memory quantities,
            uint256 next
        );

    function getItayoseEstimation(
        uint8 orderBookId
    )
        external
        view
        returns (
            uint256 openingUnitPrice,
            uint256 lastLendUnitPrice,
            uint256 lastBorrowUnitPrice,
            uint256 totalOffsetAmount
        );

    function getMaturity(uint8 orderBookId) external view returns (uint256);

    function getMaturities(
        uint8[] calldata orderBookIds
    ) external view returns (uint256[] memory maturities);

    function getCurrency() external view returns (bytes32);

    function getOrderFeeRate() external view returns (uint256);

    function getCircuitBreakerLimitRange() external view returns (uint256);

    function getOpeningDate(uint8 orderBookId) external view returns (uint256);

    function isReady(uint8 orderBookId) external view returns (bool);

    function isMatured(uint8 orderBookId) external view returns (bool);

    function isOpened(uint8 orderBookId) external view returns (bool);

    function isItayosePeriod(uint8 orderBookId) external view returns (bool);

    function isPreOrderPeriod(uint8 orderBookId) external returns (bool);

    function getItayoseLog(uint256 maturity) external view returns (ItayoseLog memory);

    function getOrder(
        uint8 orderBookId,
        uint48 orderId
    )
        external
        view
        returns (
            ProtocolTypes.Side,
            uint256 unitPrice,
            uint256 maturity,
            address maker,
            uint256 amount,
            uint256 timestamp,
            bool isPreOrder
        );

    function getTotalAmountFromLendOrders(
        uint8 orderBookId,
        address user
    )
        external
        view
        returns (
            uint256 activeAmount,
            uint256 inactiveAmount,
            uint256 inactiveFutureValue,
            uint256 maturity
        );

    function getTotalAmountFromBorrowOrders(
        uint8 orderBookId,
        address user,
        uint256 _minUnitPrice
    )
        external
        view
        returns (
            uint256 activeAmount,
            uint256 inactiveAmount,
            uint256 inactiveFutureValue,
            uint256 maturity
        );

    function getLendOrderIds(
        uint8 orderBookId,
        address user
    ) external view returns (uint48[] memory activeOrderIds, uint48[] memory inActiveOrderIds);

    function getBorrowOrderIds(
        uint8 orderBookId,
        address user
    ) external view returns (uint48[] memory activeOrderIds, uint48[] memory inActiveOrderIds);

    function calculateFilledAmount(
        uint8 orderBookId,
        ProtocolTypes.Side side,
        uint256 amount,
        uint256 unitPrice
    )
        external
        view
        returns (
            uint256 lastUnitPrice,
            uint256 filledAmount,
            uint256 filledAmountInFV,
            uint256 feeInFV,
            uint256 placedAmount
        );

    function createOrderBook(
        uint256 maturity,
        uint256 openingDate,
        uint256 preOpeningDate
    ) external returns (uint8 orderBookId);

    function executeAutoRoll(
        uint8 maturedOrderBookId,
        uint8 newNearestOrderBookId,
        uint256 newMaturity,
        uint256 openingDate,
        uint256 autoRollUnitPrice
    ) external;

    function cancelOrder(uint8 orderBookId, address user, uint48 orderId) external;

    function executeOrder(
        uint8 orderBookId,
        ProtocolTypes.Side side,
        address account,
        uint256 amount,
        uint256 unitPrice
    )
        external
        returns (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 feeInFV
        );

    function executePreOrder(
        uint8 orderBookId,
        ProtocolTypes.Side side,
        address user,
        uint256 amount,
        uint256 unitPrice
    ) external;

    function unwindPosition(
        uint8 orderBookId,
        ProtocolTypes.Side side,
        address user,
        uint256 futureValue
    )
        external
        returns (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 feeInFV
        );

    function executeItayoseCall(
        uint8 orderBookId
    )
        external
        returns (
            uint256 openingUnitPrice,
            uint256 totalOffsetAmount,
            uint256 openingDate,
            PartiallyFilledOrder memory partiallyFilledLendingOrder,
            PartiallyFilledOrder memory partiallyFilledBorrowingOrder
        );

    function cleanUpOrders(
        uint8 orderBookId,
        address user
    )
        external
        returns (
            uint256 activeLendOrderCount,
            uint256 activeBorrowOrderCount,
            uint256 removedLendOrderFutureValue,
            uint256 removedBorrowOrderFutureValue,
            uint256 removedLendOrderAmount,
            uint256 removedBorrowOrderAmount,
            uint256 maturity
        );

    function updateOrderFeeRate(uint256 orderFeeRate) external;

    function updateCircuitBreakerLimitRange(uint256 limitRange) external;

    function pause() external;

    function unpause() external;
}
