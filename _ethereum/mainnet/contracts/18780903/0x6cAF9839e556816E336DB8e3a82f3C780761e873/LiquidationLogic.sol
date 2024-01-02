// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./SafeCast.sol";
// interfaces
import "./IFutureValueVault.sol";
import "./ILiquidationReceiver.sol";
// libraries
import "./AddressResolverLib.sol";
import "./FundManagementLogic.sol";
import "./RoundingUint256.sol";
// storages
import "./LendingMarketControllerStorage.sol";

library LiquidationLogic {
    using RoundingUint256 for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    error NoDebt(address user, bytes32 ccy, uint256 maturity);
    error NoLiquidationAmount(address user, bytes32 ccy);
    error InvalidLiquidation();
    error InvalidRepaymentAmount();
    error NotRepaymentPeriod();
    error NotCollateralCurrency(bytes32 ccy);

    struct ExecuteLiquidationVars {
        uint256 liquidationAmountInCollateralCcy;
        uint256 liquidationAmountInDebtCcy;
        uint256 protocolFeeInCollateralCcy;
        uint256 liquidatorFeeInCollateralCcy;
        bool isDefaultMarket;
        uint256 receivedCollateralAmount;
    }

    event LiquidationExecuted(
        address indexed user,
        bytes32 collateralCcy,
        bytes32 indexed debtCcy,
        uint256 indexed debtMaturity,
        uint256 debtAmount
    );

    event ForcedRepaymentExecuted(
        address indexed user,
        bytes32 collateralCcy,
        bytes32 indexed debtCcy,
        uint256 indexed debtMaturity,
        uint256 debtAmount
    );

    function executeLiquidation(
        address _liquidator,
        address _user,
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _debtMaturity
    ) external {
        if (!AddressResolverLib.tokenVault().isCollateral(_collateralCcy)) {
            revert NotCollateralCurrency(_collateralCcy);
        }

        ExecuteLiquidationVars memory vars;

        vars.isDefaultMarket =
            Storage.slot().maturityOrderBookIds[_debtCcy][_debtMaturity] ==
            Storage.slot().orderBookIdLists[_debtCcy][0];

        // In order to liquidate using user collateral, inactive order IDs must be cleaned
        // and converted to actual funds first.
        FundManagementLogic.cleanUpFunds(_collateralCcy, _user);
        FundManagementLogic.cleanUpFunds(_debtCcy, _user);

        uint256 debtAmount = FundManagementLogic
            .getActualFunds(_debtCcy, _debtMaturity, _user, 0)
            .debtAmount;

        if (debtAmount == 0) revert NoDebt(_user, _debtCcy, _debtMaturity);

        (
            vars.liquidationAmountInCollateralCcy,
            vars.protocolFeeInCollateralCcy,
            vars.liquidatorFeeInCollateralCcy
        ) = AddressResolverLib.tokenVault().getLiquidationAmount(
            _user,
            _collateralCcy,
            AddressResolverLib.currencyController().convert(_debtCcy, _collateralCcy, debtAmount)
        );

        if (vars.liquidationAmountInCollateralCcy == 0) {
            revert NoLiquidationAmount(_user, _collateralCcy);
        }

        vars.liquidationAmountInDebtCcy = AddressResolverLib.currencyController().convert(
            _collateralCcy,
            _debtCcy,
            vars.liquidationAmountInCollateralCcy
        );

        // Transfer collateral from users to liquidators and reserve funds.
        vars.receivedCollateralAmount =
            vars.liquidationAmountInCollateralCcy +
            vars.liquidatorFeeInCollateralCcy;

        uint256 untransferredAmount = _transferCollateral(
            _user,
            _liquidator,
            _collateralCcy,
            vars.receivedCollateralAmount
        );

        if (untransferredAmount == 0) {
            _transferCollateral(
                _user,
                address(AddressResolverLib.reserveFund()),
                _collateralCcy,
                vars.protocolFeeInCollateralCcy
            );
        } else if (untransferredAmount > 0) {
            (
                uint256 untransferredAmountInDebtCcy,
                uint256 receivedCollateralAmountInDebtCcy,
                uint256 liquidatorFeeInDebtCcy
            ) = _convertLiquidationAmounts(
                    _collateralCcy,
                    _debtCcy,
                    untransferredAmount,
                    vars.receivedCollateralAmount,
                    vars.liquidatorFeeInCollateralCcy
                );

            // Use reserve funds to cover insolvent amounts if user does not have collateral in other currencies.
            if (
                !AddressResolverLib.reserveFund().isPaused() &&
                AddressResolverLib.tokenVault().getTotalCollateralAmount(_user) == 0
            ) {
                untransferredAmountInDebtCcy = _transferPositionsPerMaturity(
                    address(AddressResolverLib.reserveFund()),
                    _liquidator,
                    _debtCcy,
                    _debtMaturity,
                    untransferredAmountInDebtCcy.toInt256(),
                    vars.isDefaultMarket
                ).toUint256();
            }

            // Adjust the liquidation amount for debt.
            vars.liquidationAmountInDebtCcy = _calculateTransferredAmount(
                receivedCollateralAmountInDebtCcy,
                untransferredAmountInDebtCcy,
                liquidatorFeeInDebtCcy
            );
        }

        if (_liquidator.code.length > 0) {
            if (
                ILiquidationReceiver(_liquidator).executeOperationForCollateral(
                    _liquidator,
                    _user,
                    _collateralCcy,
                    vars.receivedCollateralAmount
                ) == false
            ) revert ILiquidationReceiver.InvalidOperationExecution();
        }

        // Transfer the debt from users to liquidators
        if (vars.liquidationAmountInDebtCcy > 0) {
            _transferPositionsPerMaturity(
                _user,
                _liquidator,
                _debtCcy,
                _debtMaturity,
                -vars.liquidationAmountInDebtCcy.toInt256(),
                vars.isDefaultMarket
            );

            if (_liquidator.code.length > 0) {
                if (
                    ILiquidationReceiver(_liquidator).executeOperationForDebt(
                        _liquidator,
                        _user,
                        _collateralCcy,
                        vars.receivedCollateralAmount,
                        _debtCcy,
                        _debtMaturity,
                        vars.liquidationAmountInDebtCcy
                    ) == false
                ) revert ILiquidationReceiver.InvalidOperationExecution();
            }
        }

        if (!AddressResolverLib.tokenVault().isCovered(_liquidator)) revert InvalidLiquidation();

        emit LiquidationExecuted(
            _user,
            _collateralCcy,
            _debtCcy,
            _debtMaturity,
            vars.liquidationAmountInDebtCcy
        );
    }

    function executeForcedRepayment(
        address _executor,
        address _user,
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _debtMaturity
    ) external {
        if (
            AddressResolverLib.currencyController().currencyExists(_debtCcy) ||
            block.timestamp < _debtMaturity + 1 weeks
        ) {
            revert NotRepaymentPeriod();
        }

        if (!AddressResolverLib.tokenVault().isCollateral(_collateralCcy)) {
            revert NotCollateralCurrency(_collateralCcy);
        }

        // In order to liquidate using user collateral, inactive order IDs must be cleaned
        // and converted to actual funds first.
        FundManagementLogic.cleanUpFunds(_collateralCcy, _user);
        FundManagementLogic.cleanUpFunds(_debtCcy, _user);

        FundManagementLogic.ActualFunds memory funds = FundManagementLogic.getActualFunds(
            _debtCcy,
            _debtMaturity,
            _user,
            0
        );

        if (funds.futureValue >= 0) revert NoDebt(_user, _debtCcy, _debtMaturity);

        uint256 liquidationAmountInDebtCcy = (-funds.futureValue).toUint256();
        uint256 liquidationAmountInCollateralCcy = AddressResolverLib.currencyController().convert(
            _debtCcy,
            _collateralCcy,
            liquidationAmountInDebtCcy
        );

        (
            uint256 protocolFeeInCollateralCcy,
            uint256 liquidatorFeeInCollateralCcy
        ) = AddressResolverLib.tokenVault().calculateLiquidationFees(
                liquidationAmountInCollateralCcy
            );

        uint256 receivedCollateralAmount = liquidationAmountInCollateralCcy +
            liquidatorFeeInCollateralCcy;

        uint256 untransferredAmount = _transferCollateral(
            _user,
            _executor,
            _collateralCcy,
            receivedCollateralAmount
        );

        if (untransferredAmount == 0) {
            _transferCollateral(
                _user,
                address(AddressResolverLib.reserveFund()),
                _collateralCcy,
                protocolFeeInCollateralCcy
            );
        } else {
            (
                uint256 untransferredAmountInDebtCcy,
                uint256 receivedCollateralAmountInDebtCcy,
                uint256 liquidatorFeeInDebtCcy
            ) = _convertLiquidationAmounts(
                    _collateralCcy,
                    _debtCcy,
                    untransferredAmount,
                    receivedCollateralAmount,
                    liquidatorFeeInCollateralCcy
                );

            // Adjust the liquidation amount for debt.
            liquidationAmountInDebtCcy = _calculateTransferredAmount(
                receivedCollateralAmountInDebtCcy,
                untransferredAmountInDebtCcy,
                liquidatorFeeInDebtCcy
            );
        }

        if (_executor.code.length > 0) {
            if (
                ILiquidationReceiver(_executor).executeOperationForCollateral(
                    _executor,
                    _user,
                    _collateralCcy,
                    receivedCollateralAmount
                ) == false
            ) revert ILiquidationReceiver.InvalidOperationExecution();

            if (
                ILiquidationReceiver(_executor).executeOperationForDebt(
                    _executor,
                    _user,
                    _collateralCcy,
                    receivedCollateralAmount,
                    _debtCcy,
                    _debtMaturity,
                    liquidationAmountInDebtCcy
                ) == false
            ) revert ILiquidationReceiver.InvalidOperationExecution();
        }

        AddressResolverLib.tokenVault().transferFrom(
            _debtCcy,
            _executor,
            _user,
            liquidationAmountInDebtCcy
        );

        uint256 repaymentAmount = FundManagementLogic.executeRepayment(
            _debtCcy,
            _debtMaturity,
            _user,
            liquidationAmountInDebtCcy
        );

        if (repaymentAmount != liquidationAmountInDebtCcy) revert InvalidRepaymentAmount();

        emit ForcedRepaymentExecuted(
            _user,
            _collateralCcy,
            _debtCcy,
            _debtMaturity,
            liquidationAmountInDebtCcy
        );
    }

    function _transferCollateral(
        address _from,
        address _to,
        bytes32 _ccy,
        uint256 _amount
    ) internal returns (uint256 untransferredAmount) {
        untransferredAmount = AddressResolverLib.tokenVault().transferFrom(
            _ccy,
            _from,
            _to,
            _amount
        );

        // If `untransferredAmount` is not 0, the user has not enough deposit in the collateral currency.
        // Therefore, the liquidators and the reserve fund obtain zero-coupon bonds instead of the user's collateral.
        if (untransferredAmount > 0) {
            untransferredAmount = _transferPositionsPerCurrency(
                _from,
                _to,
                _ccy,
                untransferredAmount.toInt256()
            ).toUint256();
        }
    }

    function _transferPositionsPerCurrency(
        address _from,
        address _to,
        bytes32 _ccy,
        int256 _amount
    ) internal returns (int256 untransferredAmount) {
        untransferredAmount = _transferGenesisValue(_from, _to, _ccy, _amount);

        uint256[] memory maturities = FundManagementLogic.getUsedMaturities(_ccy, _from);

        for (uint256 i; i < maturities.length; i++) {
            if (untransferredAmount == 0) {
                break;
            }

            untransferredAmount = _transferFutureValues(
                _from,
                _to,
                _ccy,
                maturities[i],
                untransferredAmount
            );
        }
    }

    function _transferPositionsPerMaturity(
        address _from,
        address _to,
        bytes32 _ccy,
        uint256 _maturity,
        int256 _amount,
        bool _isDefaultMarket
    ) internal returns (int256 untransferredAmount) {
        untransferredAmount = _isDefaultMarket
            ? _transferGenesisValue(_from, _to, _ccy, _amount)
            : _amount;

        untransferredAmount = _transferFutureValues(
            _from,
            _to,
            _ccy,
            _maturity,
            untransferredAmount
        );
    }

    function _transferGenesisValue(
        address _from,
        address _to,
        bytes32 _ccy,
        int256 _amount
    ) internal returns (int256 untransferredAmount) {
        untransferredAmount = _amount;
        bool isDebt = _amount < 0;

        int256 userGVAmount = AddressResolverLib.genesisValueVault().getBalance(_ccy, _from);

        if ((isDebt && userGVAmount < 0) || (!isDebt && userGVAmount > 0)) {
            uint256 currentMaturity = AddressResolverLib.genesisValueVault().getCurrentMaturity(
                _ccy
            );

            int256 gvAmount = AddressResolverLib.genesisValueVault().calculateGVFromFV(
                _ccy,
                0,
                FundManagementLogic.calculateFVFromPV(_ccy, currentMaturity, untransferredAmount)
            );

            if ((isDebt && userGVAmount > gvAmount) || (!isDebt && userGVAmount < gvAmount)) {
                gvAmount = userGVAmount;
            }

            // Due to the negative genesis value, the liquidator's genesis value is decreased.
            AddressResolverLib.genesisValueVault().transferFrom(_ccy, _from, _to, gvAmount);

            untransferredAmount -= FundManagementLogic.calculatePVFromFV(
                _ccy,
                currentMaturity,
                AddressResolverLib.genesisValueVault().calculateFVFromGV(_ccy, 0, gvAmount)
            );

            FundManagementLogic.registerCurrency(_ccy, _to);
        }
    }

    function _transferFutureValues(
        address _from,
        address _to,
        bytes32 _ccy,
        uint256 _maturity,
        int256 _amount
    ) internal returns (int256 untransferredAmount) {
        untransferredAmount = _amount;
        bool isDebt = _amount < 0;

        IFutureValueVault futureValueVault = IFutureValueVault(
            Storage.slot().futureValueVaults[_ccy]
        );
        uint8 orderBookId = Storage.slot().maturityOrderBookIds[_ccy][_maturity];

        (int256 userFVAmount, ) = futureValueVault.getBalance(orderBookId, _from);

        if ((isDebt && userFVAmount < 0) || (!isDebt && userFVAmount > 0)) {
            int256 fvAmount = FundManagementLogic.calculateFVFromPV(
                _ccy,
                _maturity,
                untransferredAmount
            );

            if ((isDebt && userFVAmount > fvAmount) || (!isDebt && userFVAmount < fvAmount)) {
                fvAmount = userFVAmount;
            }

            futureValueVault.transferFrom(orderBookId, _from, _to, fvAmount, _maturity);
            untransferredAmount -= FundManagementLogic.calculatePVFromFV(_ccy, _maturity, fvAmount);

            FundManagementLogic.registerCurrencyAndMaturity(_ccy, _maturity, _to);
        }
    }

    function _convertLiquidationAmounts(
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _untransferredAmount,
        uint256 _receivedCollateralAmount,
        uint256 _liquidatorFeeInCollateralCcy
    )
        internal
        view
        returns (
            uint256 untransferredAmountInDebtCcy,
            uint256 receivedCollateralAmountInDebtCcy,
            uint256 liquidatorFeeInDebtCcy
        )
    {
        uint256[] memory amountsInCollateralCcy = new uint256[](3);
        amountsInCollateralCcy[0] = _untransferredAmount;
        amountsInCollateralCcy[1] = _receivedCollateralAmount;
        amountsInCollateralCcy[2] = _liquidatorFeeInCollateralCcy;

        uint256[] memory amountsInDebtCcy = AddressResolverLib.currencyController().convert(
            _collateralCcy,
            _debtCcy,
            amountsInCollateralCcy
        );

        untransferredAmountInDebtCcy = amountsInDebtCcy[0];
        receivedCollateralAmountInDebtCcy = amountsInDebtCcy[1];
        liquidatorFeeInDebtCcy = amountsInDebtCcy[2];
    }

    function _calculateTransferredAmount(
        uint256 totalAmount,
        uint256 untransferredAmount,
        uint256 feeAmount
    ) internal pure returns (uint256) {
        // NOTE: The formula is:
        // transferredTotalAmount = totalAmount - untransferredAmount;
        // untransferredFeeAmount = feeAmount * (transferredTotalAmount / totalAmount);
        uint256 transferredTotalAmount = totalAmount - untransferredAmount;
        uint256 untransferredFeeAmount = (feeAmount * transferredTotalAmount).div(totalAmount);

        return transferredTotalAmount - untransferredFeeAmount;
    }
}
