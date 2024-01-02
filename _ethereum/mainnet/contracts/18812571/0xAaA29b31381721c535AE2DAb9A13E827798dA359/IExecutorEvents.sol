// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

enum ExecutorIntegration {
    ZeroX,
    GMX,
    SnxPerpsV2,
    GMXOrderBook
}

// These are all in the one interface to make it easier to track all the events
interface IExecutorEvents {
    // 0x
    event ZeroXSwap(
        address indexed sellTokenAddress,
        uint sellAmount,
        address indexed buyTokenAddress,
        uint buyAmount,
        uint amountReceived,
        uint unitPrice
    );

    // Gmx V1
    event GmxV1CreateIncreasePosition(
        bool isLong,
        address indexToken,
        address collateralToken,
        uint sizeDelta,
        uint collateralAmount,
        uint acceptablePrice
    );

    event GmxV1CreateDecreasePosition(
        bool isLong,
        address indexToken,
        address collateralToken,
        uint sizeDelta,
        uint collateralDelta,
        uint acceptablePrice
    );

    event GmxV1Callback(
        bool isIncrease,
        bool isLong,
        address indexToken,
        address collateralToken,
        bool wasExecuted,
        uint executionPrice
    );

    event GmxV1CreateDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    );

    event GmxV1UpdateDecreaseOrder(
        uint256 _orderIndex,
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    );

    event GmxV1CancelDecreaseOrder(
        uint256 _orderIndex,
        address _indexToken,
        address _collateralToken,
        bool _isLong
    );

    // Perps V2
    event PerpsV2ExecutedManagerActionDeposit(
        address wrapper,
        address perpMarket,
        address inputToken,
        uint inputTokenAmount
    );

    event PerpsV2ExecutedManagerActionWithdraw(
        address wrapper,
        address perpMarket,
        address outputToken,
        uint outputTokenAmount
    );

    event PerpsV2ExecutedManagerActionSubmitOrder(
        address wrapper,
        address perpMarket,
        int sizeDelta,
        uint desiredFillPrice
    );

    event PerpsV2ExecutedManagerActionSubmitCloseOrder(
        address wrapper,
        address perpMarket,
        uint desiredFillPrice
    );

    event PerpsV2ExecutedManagerActionSubmitCancelOrder(
        address wrapper,
        address perpMarket
    );
}
