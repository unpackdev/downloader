// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ProtocolTypes.sol";
import "./LendingMarketControllerStorage.sol";

interface ILendingMarketController {
    error InvalidMaturity();
    error InvalidCurrency();
    error AlreadyTerminated();
    error NotTerminated();
    error AlreadyInitialized();

    struct AdditionalFunds {
        bytes32 ccy;
        uint256 workingLendOrdersAmount;
        uint256 claimableAmount;
        uint256 workingBorrowOrdersAmount;
        uint256 debtAmount;
        uint256 lentAmount;
        uint256 borrowedAmount;
    }

    struct CalculatedTotalFunds {
        uint256 plusDepositAmountInAdditionalFundsCcy;
        uint256 minusDepositAmountInAdditionalFundsCcy;
        uint256 workingLendOrdersAmount;
        uint256 claimableAmount;
        uint256 collateralAmount;
        uint256 lentAmount;
        uint256 workingBorrowOrdersAmount;
        uint256 debtAmount;
        uint256 borrowedAmount;
    }

    struct CalculatedFunds {
        uint256 workingLendOrdersAmount;
        uint256 claimableAmount;
        uint256 collateralAmount;
        uint256 lentAmount;
        uint256 workingBorrowOrdersAmount;
        uint256 debtAmount;
        uint256 borrowedAmount;
    }

    struct GetOrderEstimationParams {
        bytes32 ccy;
        uint256 maturity;
        address user;
        ProtocolTypes.Side side;
        uint256 amount;
        uint256 unitPrice;
        uint256 additionalDepositAmount;
        bool ignoreBorrowedAmount;
    }

    function isTerminated() external view returns (bool);

    function isRedemptionRequired(address _user) external view returns (bool);

    function getMarketBasePeriod() external view returns (uint256);

    function getTerminationDate() external view returns (uint256);

    function getTerminationCurrencyCache(
        bytes32 _ccy
    ) external view returns (TerminationCurrencyCache memory);

    function getTerminationCollateralRatio(bytes32 _ccy) external view returns (uint256);

    function getMinDebtUnitPrice(bytes32 _ccy) external view returns (uint256);

    function getCurrentMinDebtUnitPrice(
        bytes32 _ccy,
        uint256 _maturity
    ) external view returns (uint256);

    function getGenesisDate(bytes32 ccy) external view returns (uint256);

    function getLendingMarket(bytes32 ccy) external view returns (address);

    function getFutureValueVault(bytes32 ccy) external view returns (address);

    function getOrderBookId(bytes32 _ccy, uint256 _maturity) external view returns (uint8);

    function getPendingOrderAmount(bytes32 _ccy, uint256 _maturity) external view returns (uint256);

    function getOrderEstimation(
        GetOrderEstimationParams calldata params
    )
        external
        view
        returns (
            uint256 lastUnitPrice,
            uint256 filledAmount,
            uint256 filledAmountInFV,
            uint256 orderFeeInFV,
            uint256 placedAmount,
            uint256 coverage,
            bool isInsufficientDepositAmount
        );

    function getMaturities(bytes32 ccy) external view returns (uint256[] memory);

    function getOrderBookIds(bytes32 ccy) external view returns (uint8[] memory);

    function getUsedCurrencies(address user) external view returns (bytes32[] memory);

    function getTotalPresentValue(bytes32 ccy, address user) external view returns (int256);

    function getTotalPresentValueInBaseCurrency(
        address user
    ) external view returns (int256 totalPresentValue);

    function getGenesisValue(bytes32 ccy, address user) external view returns (int256 genesisValue);

    function getPosition(
        bytes32 _ccy,
        uint256 _maturity,
        address _user
    ) external view returns (int256 presentValue, int256 futureValue);

    function calculateFunds(
        bytes32 ccy,
        address user,
        uint256 liquidationThresholdRate
    ) external view returns (CalculatedFunds memory funds);

    function calculateTotalFundsInBaseCurrency(
        address user,
        AdditionalFunds calldata _additionalFunds,
        uint256 liquidationThresholdRate
    ) external view returns (CalculatedTotalFunds memory calculatedFunds);

    function isInitializedLendingMarket(bytes32 ccy) external view returns (bool);

    function initializeLendingMarket(
        bytes32 ccy,
        uint256 genesisDate,
        uint256 compoundFactor,
        uint256 orderFeeRate,
        uint256 circuitBreakerLimitRange,
        uint256 minDebtUnitPrice
    ) external;

    function createOrderBook(bytes32 ccy, uint256 openingDate, uint256 preOpeningDate) external;

    function executeOrder(
        bytes32 ccy,
        uint256 maturity,
        ProtocolTypes.Side side,
        uint256 amount,
        uint256 unitPrice
    ) external returns (bool);

    function depositAndExecuteOrder(
        bytes32 ccy,
        uint256 maturity,
        ProtocolTypes.Side side,
        uint256 amount,
        uint256 unitPrice
    ) external payable returns (bool);

    function executePreOrder(
        bytes32 ccy,
        uint256 maturity,
        ProtocolTypes.Side side,
        uint256 amount,
        uint256 unitPrice
    ) external returns (bool);

    function depositAndExecutesPreOrder(
        bytes32 ccy,
        uint256 maturity,
        ProtocolTypes.Side side,
        uint256 amount,
        uint256 unitPrice
    ) external payable returns (bool);

    function unwindPosition(bytes32 ccy, uint256 maturity) external returns (bool);

    function executeItayoseCall(bytes32 ccy, uint256 maturity) external returns (bool);

    function executeRedemption(bytes32 _ccy, uint256 _maturity) external returns (bool);

    function executeRepayment(bytes32 _ccy, uint256 _maturity) external returns (bool);

    function executeEmergencySettlement() external returns (bool);

    function executeLiquidationCall(
        bytes32 collateralCcy,
        bytes32 debtCcy,
        uint256 debtMaturity,
        address user
    ) external returns (bool);

    function executeForcedRepayment(
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _debtMaturity,
        address _user
    ) external returns (bool);

    function cancelOrder(bytes32 ccy, uint256 maturity, uint48 orderId) external returns (bool);

    function rotateOrderBooks(bytes32 ccy) external;

    function executeEmergencyTermination() external;

    function pauseLendingMarket(bytes32 ccy) external returns (bool);

    function unpauseLendingMarket(bytes32 ccy) external returns (bool);

    function cleanUpAllFunds(address user) external returns (bool);

    function cleanUpFunds(bytes32 ccy, address user) external returns (uint256 activeOrderCount);

    function updateMinDebtUnitPrice(bytes32 _ccy, uint256 _minDebtUnitPrice) external;
}
