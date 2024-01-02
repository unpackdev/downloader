// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./EnumerableSet.sol";
import "./SafeCast.sol";
// interfaces
import "./ILendingMarket.sol";
import "./ILendingMarketController.sol";
import "./IFutureValueVault.sol";
// libraries
import "./AddressResolverLib.sol";
import "./Constants.sol";
import "./OrderBookLib.sol";
import "./RoundingUint256.sol";
import "./LendingMarketOperationLogic.sol";
import "./FundManagementLogic.sol";
// types
import "./ProtocolTypes.sol";
// storages
import "./LendingMarketControllerStorage.sol";

library LendingMarketUserLogic {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeCast for int256;
    using RoundingUint256 for uint256;

    error InvalidAmount();
    error FutureValueIsZero();
    error TooManyActiveOrders();
    error NotEnoughCollateral();

    function getOrderEstimation(
        ILendingMarketController.GetOrderEstimationParams memory input
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
        )
    {
        (
            lastUnitPrice,
            filledAmount,
            filledAmountInFV,
            orderFeeInFV,
            placedAmount
        ) = _calculateFilledAmount(
            input.ccy,
            input.maturity,
            input.side,
            input.amount,
            input.unitPrice
        );

        (coverage, isInsufficientDepositAmount) = _estimateCollateralCoverage(
            input.ccy,
            input.maturity,
            input.user,
            input.side,
            input.unitPrice,
            input.additionalDepositAmount,
            input.ignoreBorrowedAmount,
            filledAmount,
            filledAmountInFV,
            orderFeeInFV,
            placedAmount
        );
    }

    function executeOrder(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    ) external {
        if (_amount == 0) revert InvalidAmount();

        uint256 activeOrderCount = FundManagementLogic.cleanUpFunds(_ccy, _user);
        FundManagementLogic.registerCurrencyAndMaturity(_ccy, _maturity, _user);

        (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 feeInFV
        ) = ILendingMarket(Storage.slot().lendingMarkets[_ccy]).executeOrder(
                Storage.slot().maturityOrderBookIds[_ccy][_maturity],
                _side,
                _user,
                _amount,
                _unitPrice
            );

        uint256 filledAmount = filledOrder.amount;

        // The case that an order is placed in the order book
        if ((filledAmount + filledOrder.ignoredAmount) != _amount) {
            unchecked {
                activeOrderCount += 1;
            }
        }

        if (activeOrderCount > Constants.MAXIMUM_ORDER_COUNT) revert TooManyActiveOrders();

        updateFundsForTaker(
            _ccy,
            _maturity,
            _user,
            _side,
            filledAmount,
            filledOrder.futureValue,
            feeInFV
        );

        updateFundsForMaker(
            _ccy,
            _maturity,
            _side == ProtocolTypes.Side.LEND ? ProtocolTypes.Side.BORROW : ProtocolTypes.Side.LEND,
            partiallyFilledOrder
        );

        // Updates the pending order amount for marker's orders.
        // Since the partially filled order is updated with `updateFundsForMaker()`,
        // its amount is subtracted from `pendingOrderAmounts`.
        Storage.slot().pendingOrderAmounts[_ccy][_maturity] +=
            filledAmount -
            partiallyFilledOrder.amount;

        Storage.slot().usedCurrencies[_user].add(_ccy);

        if (!AddressResolverLib.tokenVault().isCovered(_user)) revert NotEnoughCollateral();
    }

    function executePreOrder(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    ) external {
        if (_amount == 0) revert InvalidAmount();

        uint256 activeOrderCount = FundManagementLogic.cleanUpFunds(_ccy, _user);

        if (activeOrderCount + 1 > Constants.MAXIMUM_ORDER_COUNT) revert TooManyActiveOrders();

        FundManagementLogic.registerCurrencyAndMaturity(_ccy, _maturity, _user);

        ILendingMarket(Storage.slot().lendingMarkets[_ccy]).executePreOrder(
            Storage.slot().maturityOrderBookIds[_ccy][_maturity],
            _side,
            _user,
            _amount,
            _unitPrice
        );

        Storage.slot().usedCurrencies[_user].add(_ccy);

        if (!AddressResolverLib.tokenVault().isCovered(_user)) revert NotEnoughCollateral();
    }

    function unwindPosition(bytes32 _ccy, uint256 _maturity, address _user) external {
        FundManagementLogic.cleanUpFunds(_ccy, _user);

        int256 futureValue = FundManagementLogic
            .getActualFunds(_ccy, _maturity, _user, 0)
            .futureValue;

        (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 feeInFV,
            ProtocolTypes.Side side
        ) = _unwindPosition(_ccy, _maturity, _user, futureValue);

        updateFundsForTaker(
            _ccy,
            _maturity,
            _user,
            side,
            filledOrder.amount,
            filledOrder.futureValue,
            feeInFV
        );

        updateFundsForMaker(
            _ccy,
            _maturity,
            side == ProtocolTypes.Side.LEND ? ProtocolTypes.Side.BORROW : ProtocolTypes.Side.LEND,
            partiallyFilledOrder
        );

        // Updates the pending order amount for marker's orders.
        // Since the partially filled order is updated with `updateFundsForMaker()`,
        // its amount is subtracted from `pendingOrderAmounts`.
        Storage.slot().pendingOrderAmounts[_ccy][_maturity] +=
            filledOrder.amount -
            partiallyFilledOrder.amount;

        // When the market is the nearest market and the user has only GV, a user still has future value after unwinding.
        // For that case, the `registerCurrencyAndMaturity` function needs to be called again.
        (int256 currentFutureValue, ) = IFutureValueVault(Storage.slot().futureValueVaults[_ccy])
            .getBalance(Storage.slot().maturityOrderBookIds[_ccy][_maturity], _user);

        if (currentFutureValue != 0) {
            FundManagementLogic.registerCurrencyAndMaturity(_ccy, _maturity, _user);
        }

        if (!AddressResolverLib.tokenVault().isCovered(_user)) revert NotEnoughCollateral();
    }

    function updateFundsForTaker(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        ProtocolTypes.Side _side,
        uint256 _filledAmount,
        uint256 _filledAmountInFV,
        uint256 _feeInFV
    ) public {
        if (_filledAmountInFV != 0) {
            FundManagementLogic.updateFunds(
                _ccy,
                _maturity,
                _user,
                _side,
                _filledAmount,
                _filledAmountInFV,
                _feeInFV
            );

            LendingMarketOperationLogic.updateOrderLogs(
                _ccy,
                _maturity,
                _filledAmount,
                _filledAmountInFV
            );

            emit FundManagementLogic.OrderFilled(
                _user,
                _ccy,
                _side,
                _maturity,
                _filledAmount,
                _filledAmountInFV,
                _feeInFV
            );
        }
    }

    function updateFundsForMaker(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        PartiallyFilledOrder memory partiallyFilledOrder
    ) public {
        if (partiallyFilledOrder.futureValue != 0) {
            FundManagementLogic.updateFunds(
                _ccy,
                _maturity,
                partiallyFilledOrder.maker,
                _side,
                partiallyFilledOrder.amount,
                partiallyFilledOrder.futureValue,
                0
            );

            emit FundManagementLogic.OrderPartiallyFilled(
                partiallyFilledOrder.orderId,
                partiallyFilledOrder.maker,
                _ccy,
                _side,
                _maturity,
                partiallyFilledOrder.amount,
                partiallyFilledOrder.futureValue
            );
        }
    }

    function _calculateFilledAmount(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    )
        internal
        view
        returns (
            uint256 lastUnitPrice,
            uint256 filledAmount,
            uint256 filledAmountInFV,
            uint256 orderFeeInFV,
            uint256 placedAmount
        )
    {
        (
            lastUnitPrice,
            filledAmount,
            filledAmountInFV,
            orderFeeInFV,
            placedAmount
        ) = ILendingMarket(Storage.slot().lendingMarkets[_ccy]).calculateFilledAmount(
            Storage.slot().maturityOrderBookIds[_ccy][_maturity],
            _side,
            _amount,
            _unitPrice
        );
    }

    function _estimateCollateralCoverage(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        ProtocolTypes.Side _side,
        uint256 _unitPrice,
        uint256 _additionalDepositAmount,
        bool _ignoreBorrowedAmount,
        uint256 _filledAmount,
        uint256 _filledAmountInFV,
        uint256 _orderFeeInFV,
        uint256 _placedAmount
    ) internal view returns (uint256 coverage, bool isInsufficientDepositAmount) {
        uint256 filledAmountWithFeeInFV = _filledAmountInFV;

        if (_side == ProtocolTypes.Side.LEND) {
            filledAmountWithFeeInFV -= _orderFeeInFV;
        } else {
            filledAmountWithFeeInFV += _orderFeeInFV;
        }

        uint256 filledAmountWithFeeInPV = _estimatePVFromFV(
            _ccy,
            _maturity,
            filledAmountWithFeeInFV,
            _unitPrice
        );

        ILendingMarketController.AdditionalFunds memory funds;
        funds.ccy = _ccy;
        // Store the _additionalDepositAmount in the borrowedAmount,
        // because the borrowedAmount is used as collateral.
        funds.borrowedAmount = _additionalDepositAmount;

        if (_placedAmount > 0) {
            if (_side == ProtocolTypes.Side.BORROW) {
                funds.workingBorrowOrdersAmount = _placedAmount;
            } else {
                funds.workingLendOrdersAmount = _placedAmount;
            }
        }

        if (filledAmountWithFeeInPV > 0) {
            if (_side == ProtocolTypes.Side.BORROW) {
                if (!_ignoreBorrowedAmount) {
                    funds.borrowedAmount += _filledAmount;
                }
                funds.debtAmount += filledAmountWithFeeInPV;
            } else {
                funds.lentAmount += _filledAmount;
                funds.claimableAmount += filledAmountWithFeeInPV;
            }
        }

        (coverage, isInsufficientDepositAmount) = AddressResolverLib.tokenVault().calculateCoverage(
            _user,
            funds
        );
    }

    function _estimatePVFromFV(
        bytes32 _ccy,
        uint256 _maturity,
        uint256 _amount,
        uint256 _unitPrice
    ) internal view returns (uint256) {
        uint256 marketUnitPrice = ILendingMarket(Storage.slot().lendingMarkets[_ccy])
            .getMarketUnitPrice(Storage.slot().maturityOrderBookIds[_ccy][_maturity]);

        if (marketUnitPrice == 0) {
            marketUnitPrice = _unitPrice;
        }

        return (_amount * marketUnitPrice).div(Constants.PRICE_DIGIT);
    }

    function _unwindPosition(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        int256 _futureValue
    )
        internal
        returns (
            FilledOrder memory filledOrder,
            PartiallyFilledOrder memory partiallyFilledOrder,
            uint256 feeInFV,
            ProtocolTypes.Side side
        )
    {
        if (_futureValue == 0) revert FutureValueIsZero();

        if (_futureValue > 0) {
            side = ProtocolTypes.Side.BORROW;

            (filledOrder, partiallyFilledOrder, feeInFV) = ILendingMarket(
                Storage.slot().lendingMarkets[_ccy]
            ).unwindPosition(
                    Storage.slot().maturityOrderBookIds[_ccy][_maturity],
                    side,
                    _user,
                    _futureValue.toUint256()
                );
        } else if (_futureValue < 0) {
            side = ProtocolTypes.Side.LEND;

            (filledOrder, partiallyFilledOrder, feeInFV) = ILendingMarket(
                Storage.slot().lendingMarkets[_ccy]
            ).unwindPosition(
                    Storage.slot().maturityOrderBookIds[_ccy][_maturity],
                    side,
                    _user,
                    (-_futureValue).toUint256()
                );
        }
    }
}
