// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

library Orders {
    enum OrderType {Empty, Deposit, Withdraw, Sell, Buy}
    enum OrderStatus {NonExistent, EnqueuedWaiting, EnqueuedReady, ExecutedSucceeded, ExecutedFailed, Canceled}

    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);

    event DepositEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);

    struct PairInfo {
        address pair;
        address token0;
        address token1;
    }

    struct Data {
        uint256 delay;
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => StoredOrder) orderQueue;
        address factory;
        uint256 maxGasLimit;
        uint256 gasPrice;
        uint256 gasPriceInertia;
        uint256 maxGasPriceImpact;
        mapping(uint32 => PairInfo) pairs;
        mapping(address => uint256) transferGasCosts;
        mapping(uint256 => bool) canceled;
        mapping(address => bool) depositDisabled;
        mapping(address => bool) withdrawDisabled;
        mapping(address => bool) buyDisabled;
        mapping(address => bool) sellDisabled;
    }

    struct StoredOrder {
        // slot 1
        uint8 orderType;
        uint32 validAfterTimestamp;
        uint8 unwrapAndFailure;
        uint32 deadline;
        uint32 gasLimit;
        uint32 gasPrice;
        uint112 liquidityOrRatio;
        // slot 1
        uint112 value0;
        uint112 value1;
        uint32 pairId;
        // slot2
        address to;
        uint32 minRatioChangeToSwap;
        uint32 minSwapPrice;
        uint32 maxSwapPrice;
    }

    struct DepositOrder {
        uint32 pairId;
        uint256 share0;
        uint256 share1;
        uint256 initialRatio;
        uint256 minRatioChangeToSwap;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct WithdrawOrder {
        uint32 pairId;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct SellOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareIn;
        uint256 amountOutMin;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct BuyOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareInMax;
        uint256 amountOut;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 initialRatio;
        uint256 minRatioChangeToSwap;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
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
        uint256 submitDeadline;
        uint256 executionDeadline;
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }
}
